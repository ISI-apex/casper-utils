import pylab as pl
import pandas as pd
import seaborn as sb
import numpy as np
import math
import sys
import os

#solver = 'mumps'
solver = 'superlu_dist'

fin = sys.argv[1]
fout_base = os.path.splitext(fin)[0] + f'-heatmap-zoom-{solver}'
#fout_base = os.path.splitext(fin)[0] + f'-heatmap-{solver}'
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

d = d[(d['mesh'] == 512) & (d['solver'] == solver)]


d = d.pivot_table(columns=['solver', 'mesh', 'ntasks_per_node'], index=['ntasks'], values=['runtime'])
d = d['runtime']
print(d)
print(d.columns)

d = d[solver][512]

TPN=[1,2,4,8]

nodes = {}
for ntasks in d.index:
    for tpn in d.columns:
        print("ntasks=", ntasks, "tpn=", tpn)
        #num_nodes = math.ceil(ntasks / tpn)
        num_nodes = ntasks / tpn
        if num_nodes not in nodes:
            nodes[num_nodes] = np.empty(len(TPN))
            nodes[num_nodes][:] = np.nan
        nodes[num_nodes][TPN.index(tpn)] = d[tpn][ntasks]
print(nodes)
#sys.exit(0)


for num_nodes in sorted(nodes.keys()):
    if num_nodes < 1: # tricky to interpret
        continue
    if num_nodes <= 2: # to zoom in
        continue
    pl.plot(TPN, nodes[num_nodes], label=f"Nodes: {int(num_nodes)}", marker='o')
pl.title(f'Effect of node utilization and task size ({solver})')
pl.xlabel("Tasks per node")
pl.ylabel("Execution time (s)")
pl.legend()

pl.savefig(fout_base + '.pdf', bbox_inches='tight')
pl.savefig(fout_base + '.svg', bbox_inches='tight')
pl.show()

