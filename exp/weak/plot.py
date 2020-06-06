import sys
import pandas as pd
import pylab as pl
import numpy as np
import math

def invert_poly(coeff, y):
    #print("Coeff:", coeff)
    x = np.zeros(len(y))
    print(y)
    for i in range(len(y)):
        cross_p = [coeff[0], coeff[1], coeff[2] - y[i]]
        roots = np.roots(cross_p)
        roots = roots[roots >= 0]
        print(i)
        assert len(roots) == 1
        x[i] = roots[0]
        #print("y", y[i], ": y", roots[0])
    return x

def eval_poly(coeff, x):
    return coeff[0]*x**2 + coeff[1]*x + coeff[2]

d = pd.read_csv('weak2.csv')
d = d.dropna()
d['tasks'] = d['tasks'].astype('int')
d = d[d['mesh'] >= 128] # too small problem is just noise
d['matrix'] = d['matrix'] / 1e6 # otherwise numerical issues
print(d)

d_seq = d[d['prob_size_seq'] == 1]
print(d_seq)
d_seq = d_seq.loc[d_seq.groupby(['mesh','tasks'])['time_s'].idxmin()]
d_nonseq = d[d['prob_size_seq'] == 0]
d_nonseq = d_nonseq.loc[d_nonseq.groupby(['mesh','tasks'])['time_s'].idxmin()]
print(d_seq)
print(d_nonseq)
#sys.exit()

d_unit = d_nonseq[(d_nonseq['tasks'] == 1) & (d_nonseq['tasks_per_node'] == 1)]
d_unit = d_unit.groupby('mesh')[['matrix','time_s']].min()
d_unit = d_unit.loc[d_unit.groupby('mesh')['time_s'].idxmin()]
print(d_unit)

d_m = d_unit[['matrix','time_s']].set_index('matrix')
ax = d_m.plot(marker='o')

matrix_time_coeff = np.polyfit(d_m.index, d_m['time_s'], 2)

#problem_size_min = 20
problem_size_min = 40
problem_size_max = 3333
problem_sizes = [problem_size_min]
i = 1
while problem_sizes[-1] < problem_size_max:
    problem_sizes.append(problem_size_min * 2**i)
    i += 1
problem_sizes = np.array(problem_sizes)
print("Problem sizes (unit: execution time on one core):", problem_sizes)

print("Matrix->Time coeff:", matrix_time_coeff)
matrix_sizes = invert_poly(matrix_time_coeff, problem_sizes)
print("matrix sizes", matrix_sizes)

M = np.arange(1, 12, 1)
T = eval_poly(matrix_time_coeff, M)
ax.plot(M, T, label='fit0')
ax.legend()

pl.ylim(bottom=0)
pl.ylabel("Execution Time (s)")
pl.figure()
d_m = d_unit['matrix']
ax = d_m.plot(marker='o')

mesh_matrix_coeff = np.polyfit(d_m.index, d_m, 2)
print("Mesh->Matrix coeff:", mesh_matrix_coeff)
mesh_sizes = invert_poly(mesh_matrix_coeff, matrix_sizes).astype('int')
print("mesh sizes:", mesh_sizes)

M = np.arange(1, 1024, 1)
T = eval_poly(mesh_matrix_coeff, M)
ax.plot(M, T, label='fit')
ax.legend()

pl.ylim(bottom=0)
pl.ylabel("Matrix elements")

d_m = d_unit
pl.figure()
ax = d_m['time_s'].plot(marker='o')
pl.scatter(mesh_sizes, eval_poly(matrix_time_coeff, eval_poly(mesh_matrix_coeff, mesh_sizes)), marker='s', color='r')
pl.title("Mesh -> Time")
pl.ylim(bottom=0)
pl.ylabel("Execution Time (s)")
pl.savefig("mumps_mesh_to_time.pdf", bbox_inches='tight')

mesh_time_coeff = np.polyfit(d_m.index, d_m['time_s'], 2)
M = np.arange(1, 1024, 10)
T = eval_poly(mesh_time_coeff ,M)
ax.plot(M, T, label='fit')

#mesh = 128
#guess_dbl = []
#while True:
#    guess_dbl.append(mesh)
#    mesh = round(mesh * math.sqrt(2))
#    if len(d[d['mesh'] == mesh]) == 0:
#        print("not in data", "mesh", mesh)
#        break
#print(guess_dbl)
# Data was collected for mesh sizes that are not exact...
guess_meshes_dbl_dim = [128, 256, 512, 1024] # 2048
guess_meshes_dbl_area = [128, 181, 256, 360, 512, 722, 1024, 1448, 2048]
guess_tasks = []
guess_tasks_dbl_dim = [2**i for i in range(len(guess_meshes_dbl_dim))]
guess_tasks_dbl_area = [2**i for i in range(len(guess_meshes_dbl_area))]
#guess_tasks_quad = [4**i for i in range(len(guess_meshes))]
print(" guess_meshes dbl dim", guess_meshes_dbl_dim)
print("  guess tasks dbl dim", guess_tasks_dbl_dim)
print("guess_meshes dbl area", guess_meshes_dbl_area)
print(" guess tasks dbl area", guess_tasks_dbl_area)
#print("guess_meshes", guess_meshes, "guess tasks quad", guess_tasks_quad)

def filter_entries(dat, m_meshes, m_tasks):
    indexes = []
    i = 0
    for mesh_index, row in d_nonseq.iterrows():
        for mesh, tasks in zip(m_meshes, m_tasks):
            #print("row:", row['mesh'], row['tasks'])
            #print("match:", mesh, tasks)
            match = row['mesh'] == mesh and int(row['tasks']) == tasks
            if match:
                break
        indexes.append(match)
        i += 1
    return d_nonseq[indexes]

d_guess_dbl_dim = filter_entries(d_nonseq, guess_meshes_dbl_dim, guess_tasks_dbl_dim)
print(d_guess_dbl_dim)
d_guess_dbl_area = filter_entries(d_nonseq, guess_meshes_dbl_area, guess_tasks_dbl_area)
print(d_guess_dbl_area)

pl.figure()
d_inf_res = d_nonseq[(d_nonseq['tasks'] > 1) & (d_nonseq['tasks_per_node'] > 1)]
d_min = d_inf_res.loc[d_inf_res.groupby('mesh')['time_s'].idxmin()].set_index('mesh')
pl.plot(d_guess_dbl_dim['mesh'], d_guess_dbl_dim['time_s'], marker='o', label='Resources: proportional to mesh dim', color='red')
pl.plot(d_guess_dbl_area['mesh'], d_guess_dbl_area['time_s'], marker='o', label='Resources: proportional to mesh area', color='orange')
pl.plot(d_seq['mesh'], d_seq['time_s'], marker='o', label='Resources: proportional to problem size', color='green')
pl.plot(d_min.index, d_min['time_s'], marker='o', label='Resources: hand-optimized', color='blue')
pl.legend()
pl.title("Weak scaling")
pl.xlabel("mesh")
pl.ylim(bottom=0)
pl.ylabel("Execution Time (s)")
pl.savefig("mumps_weak_scaling.pdf", bbox_inches='tight')

pl.figure()
ax1 = pl.subplot(211)
#ax = d_unit['time_s'].plot(marker='o')
ax1.plot(d_unit.index, d_unit['time_s'], marker='o', label='Resources: single core')
ax1.plot(d_seq['mesh'], d_seq['time_s'], marker='o', label='Resources: proportional to problem size', color='green')
ax1.plot(d_min.index, d_min['time_s'], marker='o', label='Resources: hand-optimized', color='blue')
pl.title("Weak scaling (constrast with single core)")
ax1.set_ylabel("Execution Time (s)")

weak_scal_coeff = np.polyfit(d_seq['mesh'], d_seq['time_s'], 2)
M = np.arange(1, 4096, 10)
T = eval_poly(weak_scal_coeff, M)
ax1.plot(M, T, label='fit', linestyle='--', color='green')
ax1.set_ylim(bottom=0)
ax1.legend()

#pl.figure()
ax2 = pl.subplot(212, sharex=ax1)
# fixup because we should be running 1024, but we actually ran 768, because strange MPI error for 128 nodes (x8 tasks).
tasks_fixed = pd.concat([d_seq['tasks'].iloc[:-1], pd.Series([1024],name='tasks')], ignore_index=True, axis=0)
ax2.plot(d_seq['mesh'], tasks_fixed, marker='o')
ax2.set_xlabel("Mesh")
ax2.set_ylabel("Tasks (ranks)")

mesh_tasks_coeff = np.polyfit(d_seq['mesh'], tasks_fixed, 2)
M = np.arange(1, 4096, 10)
T = eval_poly(mesh_tasks_coeff, M)
ax2.plot(M, T, label='fit', linestyle='--', color='green')
ax2.set_ylim(bottom=0)
ax2.legend()

pl.savefig("mumps_weak_scaling_vs_single.pdf", bbox_inches='tight')

#pl.figure()
#pl.plot(d_seq['mesh'], d_seq['time_s'], marker='o')
#pl.title("Weak scaling (vs problem size; proportional resources)")
#pl.xlabel("mesh")
#pl.ylim(bottom=0)
#pl.ylabel("Execution Time (s)")
#
pl.figure()
d_speedup = d_unit.join(d_min, on='mesh', how='inner', lsuffix='_unit')
d_speedup['speedup'] = d_speedup['time_s_unit'] / d_speedup['time_s']
print(d_speedup)
#d_speedup = d_speedup[d_speedup.index >= 128]
pl.title("Speedup vs Problem Size")
pl.plot(d_speedup.index, d_speedup['speedup'], marker='o')
pl.xlabel("mesh")
pl.ylim(bottom=1)
pl.ylabel("Speedup (T_one_task / T_x_tasks)")
pl.savefig("mumps_speedup_vs_problem_size.pdf", bbox_inches='tight')

pl.figure()
pl.title("Speedup vs Tasks")
d_speedup_sorted = d_speedup.sort_values('tasks')
pl.plot(d_speedup_sorted['tasks'], d_speedup_sorted['speedup'], marker='o')
pl.xlabel("Number of Tasks (Ranks)")
pl.ylim(bottom=1)
pl.ylabel("Speedup (T_one_task / T_x_tasks)")
pl.savefig("mumps_speedup_vs_tasks.pdf", bbox_inches='tight')

pl.figure()
pl.title("Strong scaling")
pl.xlabel("Tasks")
pl.ylabel("Execution time (s)")
mesh_sizes = [256, 512, 1024, 2048]
for ms in mesh_sizes:
    d_ms = d[d['mesh'] == ms]
    pl.plot(d_ms['tasks'], d_ms['time_s'], marker='o', label='Mesh: ' + str(ms))
pl.legend()
pl.savefig("mumps_strong_scaling.pdf", bbox_inches='tight')

pl.figure()
pl.title("Strong scaling (speedup)")
pl.xlabel("Tasks")
pl.ylabel("Speedup")
print("dunit", d_unit)
mesh_sizes = [256, 512, 1024] # no unit value for 2048
for ms in mesh_sizes:
    d_ms = d[d['mesh'] == ms].set_index('mesh')
    d_unit_ms = d_unit[d_unit.index == ms]
    #print("concatting:", pd.DataFrame(dict(mesh=d_ms.index)))
    #d_ms = pd.concat([d_ms, pd.DataFrame(dict(mesh=d_ms.index), index=d_ms.index)], axis=1)
    d_speedup_ms = d_unit_ms.join(d_ms, on='mesh', how='inner', lsuffix='_unit')
    print("unit", d_unit_ms)
    print("min", d_ms)
    print("speedup", d_speedup_ms)
    d_speedup_ms['speedup'] =  d_speedup_ms['time_s_unit'] / d_speedup_ms['time_s']
    pl.plot(d_speedup_ms['tasks'], d_speedup_ms['speedup'], marker='o', label='Mesh: ' + str(ms))
pl.legend()
pl.savefig("mumps_strong_scaling_speedup.pdf", bbox_inches='tight')

print(d_min)
pl.figure()
pl.title("Max beneficial resources")
pl.plot(d_min.index, d_min['tasks'], marker='o')
pl.xlabel("Mesh size")
pl.ylabel("Tasks = Ranks = Processors")
pl.savefig("mumps_max_beneficial_resources.pdf", bbox_inches='tight')

pl.show()
