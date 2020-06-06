import pylab as pl
import pandas as pd
import numpy as np
import matplotlib as mpl
import sys
import re

#mpl.rc('pdf', fonttype=42)

d = pd.read_csv('pp.csv')

PE_PRETTY={
    'cpu_e5-2665': 'cpu_sandybridge',
    'cpu_e5-2670': 'cpu_sandybridge70',
    'cpu_e5-2640v4': 'cpu_broadwell',
    'cpu_e5-2640v3': 'cpu_haswell',
    'cpu_g-6130': 'cpu_skylake',

    'gpu_tesla_k20': 'gpu_k20',
    'gpu_tesla_k40c': 'gpu_k40',
    'gpu_tesla_k40': 'gpu_k40',
    'gpu_tesla_p100': 'gpu_p100',
    'gpu_tesla_v100': 'gpu_v100',
}

SOLVER_PRETTY={
    'mumps': 'MUM',
    'superlu_dist': 'SUD',
    'pastix': 'PSX',
}
LEGEND_ORDER=[
        SOLVER_PRETTY['mumps'] + ':' + PE_PRETTY['cpu_e5-2665'],
        SOLVER_PRETTY['mumps'] + ':' + PE_PRETTY['cpu_e5-2640v3'],
        #SOLVER_PRETTY['mumps'] + ':' + PE_PRETTY['cpu_e5-2670'],
        #SOLVER_PRETTY['mumps'] + ':' + PE_PRETTY['cpu_e5-2640v4'],
        SOLVER_PRETTY['mumps'] + ':' + PE_PRETTY['cpu_g-6130'],

        SOLVER_PRETTY['pastix'] + ':' + PE_PRETTY['cpu_e5-2665'],
        SOLVER_PRETTY['pastix'] + ':' + PE_PRETTY['gpu_tesla_k20'],
        SOLVER_PRETTY['pastix'] + ':' + PE_PRETTY['cpu_e5-2640v3'],
        SOLVER_PRETTY['pastix'] + ':' + PE_PRETTY['gpu_tesla_k40'],
        #SOLVER_PRETTY['pastix'] + ':' + PE_PRETTY['cpu_e5-2670'],
        #SOLVER_PRETTY['pastix'] + ':' + PE_PRETTY['gpu_tesla_k40c'],
        SOLVER_PRETTY['pastix'] + ':' + PE_PRETTY['cpu_e5-2640v4'],
        SOLVER_PRETTY['pastix'] + ':' + PE_PRETTY['gpu_tesla_p100'],
        SOLVER_PRETTY['pastix'] + ':' + PE_PRETTY['cpu_g-6130'],
        SOLVER_PRETTY['pastix'] + ':' + PE_PRETTY['gpu_tesla_v100'],

        SOLVER_PRETTY['superlu_dist'] + ':' + PE_PRETTY['cpu_e5-2665'],
        SOLVER_PRETTY['superlu_dist'] + ':' + PE_PRETTY['gpu_tesla_k20'],
        SOLVER_PRETTY['superlu_dist'] + ':' + PE_PRETTY['cpu_e5-2640v3'],
        SOLVER_PRETTY['superlu_dist'] + ':' + PE_PRETTY['gpu_tesla_k40'],
        #SOLVER_PRETTY['superlu_dist'] + ':' + PE_PRETTY['cpu_e5-2670'],
        #SOLVER_PRETTY['superlu_dist'] + ':' + PE_PRETTY['gpu_tesla_k40c'],
        SOLVER_PRETTY['superlu_dist'] + ':' + PE_PRETTY['cpu_e5-2640v4'],
        SOLVER_PRETTY['superlu_dist'] + ':' + PE_PRETTY['gpu_tesla_p100'],
        SOLVER_PRETTY['superlu_dist'] + ':' + PE_PRETTY['cpu_g-6130'],
        SOLVER_PRETTY['superlu_dist'] + ':' + PE_PRETTY['gpu_tesla_v100'],
]

# 64 is the first run in the sequecne, and we use it for warmup, so don't count it
d = d[(64 < d['mesh']) & (d['mesh'] <= 768)]
print(d)
#d = d.set_index(['solver','pe','mesh'])
#d = d.pivot(columns=['solver', 'pe'], values='time')
#d = d.pivot(columns='solver', values='time')
#d = d.pivot(index='mesh', columns='solver', values='time')
d = d.pivot_table(columns=['solver', 'pe'], index=['mesh'], values=['time'])
print(d)

dt = d['time']

spread = {}

fig = pl.figure(figsize=(10,13))

gs = mpl.gridspec.GridSpec(2, 1, height_ratios=[3,1])

#pl.subplot(211)
ax1 = pl.subplot(gs[0])

for solver, pe in dt.columns:
    ds = dt[solver][pe]
    mesh_dim = ds.index
    mesh_elems = [x**2 for x in mesh_dim]
    if solver == 'pastix':
        color = 'red'
    elif solver == 'superlu_dist':
        color = 'green'
    else:
        color = 'blue'
    if re.match(r'^cpu_g', pe):
        marker = 'o'
    elif re.match(r'^cpu_e5-2640v4.*', pe):
        marker = 's'
    elif re.match(r'^cpu_e5-2670.*', pe) or re.match(r'^cpu_e5-2640v3.*', pe):
        marker = '^'
    elif re.match(r'^cpu_e5-2665.*', pe):
        marker = 'v'
    elif re.match(r'^gpu_tesla_v100.*', pe):
        marker = 'o'
    elif re.match(r'^gpu_tesla_p100.*', pe):
        marker = 's'
    elif re.match(r'^gpu_tesla_k40c.*', pe) or re.match(r'^gpu_tesla_k40.*', pe):
        marker = '^'
    elif re.match(r'^gpu_tesla_k20.*', pe):
        marker = 'v'
    else:
        raise Exception("no marker for " + pe)

    #if re.match(r'^gpu.*', pe):
    #    markerfacecolor=color
    #elif re.match(r'^gpu.*', pe):
    #    markerfacecolor='white'

    #if re.match(r'^cpu_e5-2670.*', pe):
    #    markerfacecolor='white'
    #elif re.match(r'^cpu.*', pe):
    #    markerfacecolor=color

    if re.match(r'^cpu.*', pe):
        markerfacecolor='white'
    elif re.match(r'^gpu.*', pe):
        markerfacecolor=color
    #pe_f = pe.replace('tesla_','').replace('v4','')
    pe_f = PE_PRETTY[pe]
    pl.plot(mesh_elems, ds, marker=marker, label=SOLVER_PRETTY[solver] + ':' + pe_f, color=color, markerfacecolor=markerfacecolor)

    if solver not in spread:
        spread[solver] = {}
    for mesh in ds.index:
        if  mesh not in spread[solver]:
            spread[solver][mesh] = []
        print("mesh", mesh)
        spread[solver][mesh].append(ds.loc[mesh])

print("spread", spread)

spread_ratio = {}
for solver in spread:
    spread_ratio[solver] = {}
    for mesh in spread[solver]:
        spread_ratio[solver][mesh] = max(spread[solver][mesh]) / min(spread[solver][mesh])

print("spread_ratio", spread_ratio)

spread_mesh = spread_ratio['pastix']
pp = {}
for mesh in spread_mesh:
    pp[mesh] = spread_ratio['pastix'][mesh] / spread_ratio['superlu_dist'][mesh]
print("pp", pp)

#for mesh in pp:
#    if mesh <= 128:
#        continue
#    pl.text(mesh**2 - 5000, dt['pastix']['cpu_e5-2670'][mesh] + 3, "PP=" + ("%.2f" % pp[mesh]),
#            horizontalalignment='right')

pl.title("Perf. Portability of Lid-Cavity Benchmark in Firedrake/PyOP2")
pl.ylabel("Execution Time (s)")
pl.xlabel("Mesh elements")
#pl.legend(prop={'size': 10}, loc=(1.0,0.0))
handles, labels = ax1.get_legend_handles_labels()
#handles_sorted = handles
#labels_sorted = labels


handles_sorted = []
labels_sorted = []
for label in LEGEND_ORDER:
    found = False
    for i, l in enumerate(labels):
        if l == label:
            found = True
            break
    if not found:
        raise Exception(f"Line plot for label not found: {label}")
    handles_sorted.append(handles[i])
    labels_sorted.append(labels[i])

pl.legend(handles_sorted, labels_sorted, prop={'size': 10}, ncol=3, framealpha=1.0)
#fig.set_size_inches((8,10))
#pl.margins(x=1,tight=False)
#fig.canvas.layout.width = '1000px'
#help(fig.canvas)
#class Foo:
#    width = 1000
#    height = 1200
#fig.canvas.resize(Foo())
#fig.canvas.draw()

#pl.subplot(212)
pl.subplot(gs[1], sharex=ax1)

mesh_elems = []
pp_vals = []
for mesh, pp_val in pp.items(): # dict might re-order, so restore
    mesh_elems.append(mesh**2)
    pp_vals.append(pp_val)

pl.plot(mesh_elems, pp_vals, label="PP (SuperLU_DIST vs PaStiX)")

pl.ylabel("Perf. Portability (PP)")

#pl.ticklabel_format(style="sci")

pl.xlabel("Mesh elements")
pl.legend()


## need to adjust Parameters manuall to fit legend
pl.savefig('pp.svg', bbox_inches='tight')
pl.savefig('pp.pdf', bbox_inches='tight')

pl.show()
