import pylab as pl
import pandas as pd
import sys

d = pd.read_csv('superlu-hpcc.csv')
print(d)
d = d.groupby('mesh').mean()
#d = d.set_index('mesh')
print(d)
d = d[['cpu', 'gpu_k20', 'cpu_p100', 'gpu_p100', 'cpu_v100', 'gpu_v100']]
print(d)

d.plot(marker='o')
pl.title("Cavity benchmark in Firedrake/PyOP2 (SuperLU_DIST)")
pl.ylabel("Execution Time (s)")
pl.xlabel("Mesh dimension")

pl.savefig('superludist-hpcc.pdf', bbox_inches='tight')

pl.show()
