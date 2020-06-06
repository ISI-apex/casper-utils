import pylab as pl
import pandas as pd

d = pd.read_csv('superludist.csv')
d = d.set_index('mesh')

d.plot(marker='o')
pl.title("Execution time of cavity benchmark in Firedrake/PyOP2")
pl.ylabel("Execution Time (s)")
pl.xlabel("Mesh dimension")

pl.savefig('superludist.pdf', bbox_inches='tight')

pl.show()
