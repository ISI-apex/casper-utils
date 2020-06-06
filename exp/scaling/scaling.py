import pylab as pl
import pandas as pd
import sys
import os

fin = sys.argv[1]
fout_base = os.path.splitext(fin)[0]
framework = sys.argv[2]

#d = pd.read_csv('superlu_dist-scaling2.csv')
d = pd.read_csv(fin)

# segfaults for Firedrake with multi-node on meshes >= 768
#d = d[d['mesh'] < 768]

#d = d[d['solver'] != 'pastix']

#d = d[(d['ntasks_per_node'] == 8) | (d['ntasks_per_node'] == 1)]

# For comparing effect of ntasks per node
#d = d[d['mesh'] <= 512]
#d = d[d['ntasks'] > 1]
#d = d[(d['ntasks_per_node'] == 8) | (d['ntasks_per_node'] == 4)]

# Alternatively, include only one NPC (with one exception for SuperLU_DIST, temporarily)
#d = d[(d['ntasks_per_node'] == 8) | (d['ntasks_per_node'] == 2) | (d['ntasks_per_node'] == 4)]

# Nodes as x-axis
d = d[d['ntasks_per_node'] == 8]


d = d.pivot_table(columns=['solver', 'mesh', 'ntasks_per_node'], index=['ntasks'], values=['runtime'])
d = d['runtime']
print(d)
print(d.columns)
#sys.exit(0)

#d = d.set_index('tasks')

#print(d)
#sys.exit()

pl.figure(figsize=(10,8))

SOLVER_COLORS={
        'mumps': 'blue',
        'superlu_dist': 'green',
        'pastix': 'red',
        }
MESH_MARKERS=['o', 's', 'v', '^','>','<']

mesh_marker = {}
next_marker = 0
for solver, mesh, ntasks_per_node in d.columns:
    ds = d[solver][mesh][ntasks_per_node]
    if not mesh in mesh_marker:
        mesh_marker[mesh] = next_marker
        next_marker += 1
    color = SOLVER_COLORS[solver]
    if ntasks_per_node == 4:
        markerfacecolor='none'
    else:
        markerfacecolor=color
    pl.plot(ds.index / ntasks_per_node, ds, marker=MESH_MARKERS[mesh_marker[mesh]],
            color=color, markerfacecolor=markerfacecolor,
            label=f'{solver} M:{mesh}x{mesh} NPC:{ntasks_per_node})')

pl.title(f"Scaling of solvers (Lid-Cavity in {framework})")
pl.ylabel("Execution time (s)")
#pl.xlabel("Number of tasks == MPI ranks == cores")
pl.xlabel("Nodes")
pl.legend()

pl.savefig(fout_base + '.pdf', bbox_inches='tight')
pl.savefig(fout_base + '.svg', bbox_inches='tight')
pl.show()

