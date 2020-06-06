import pylab as pl
import pandas as pd
import sys

d = pd.read_csv('pastix-hpcc.csv')
d = d.groupby('mesh').mean()
#d = d.set_index('mesh')
d = d[['total_cpu_k20', 'total_gpu_k20', 'total_cpu_p100', 'total_gpu_p100', 'total_cpu_v100', 'total_gpu_v100']]
print(d)

d.plot(marker='o')
pl.title("Cavity benchmark in Firedrake/PyOP2 (PaStiX)")
pl.ylabel("Execution Time (s)")
pl.xlabel("Mesh dimension")

#pl.savefig('pastix-hpcc.pdf', bbox_inches='tight')

pl.show()
