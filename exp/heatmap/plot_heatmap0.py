#!/usr/bin/python

import sys
import pylab as pl
import pandas as pd
import seaborn as sb

d = pd.read_csv(sys.argv[1])
d = d.pivot(index='np', columns='th', values='time_s')
print(d)
f = pl.figure()
sb.heatmap(d)
f.savefig(sys.argv[2], bbox_inches='tight')
