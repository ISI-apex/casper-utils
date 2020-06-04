import sys
import pylab as pl
import pandas as pd
import seaborn as sb

d = pd.read_csv(sys.argv[1])
d = d.pivot(index='nproc', columns='nthreads', values='time')
print(d)
f = pl.figure()
sb.heatmap(d)
f.savefig(sys.argv[2], bbox_inches='tight')
