import pandas as pd
import pylab as pl
import numpy as np
import sys

d = pd.read_csv(sys.argv[1])
d = d.fillna(0)
dg = d.groupby(['impl','tile','threads'])
d = dg.mean()['time_s']

IMPLS = ['cblur_seq', 'cblur_tiled', 'cblur_omp_def', 'cblur_omp', 'casper_def', 'casper']
PRETTY = {
        'cblur_seq': 'C\n(sequential)',
        'cblur_tiled': 'C Tiled\n(sequential)',
        'cblur_omp_def': 'C+OpenMP\n(default)',
        'cblur_omp': 'C+OpenMP\n(hand-optimized)',
        'casper_def': 'Casper\n(default sched.)',
        'casper': 'Casper\n(autotuned)',
}

pl.figure(figsize=(10,4))

x = np.arange(len(IMPLS))
w = 0.8

for i, impl in enumerate(IMPLS):
    tile_th_d = d.loc[impl]
    print(tile_th_d)
    x_impl = np.arange(x[i], x[i] + w, w/len(tile_th_d))
    print(x_impl)
    bar_width=0.85*w/len(tile_th_d)
    if impl == 'casper':
        color='b'
    else:
        color='k'
    bl = pl.bar(x_impl, tile_th_d, color=color, width=bar_width, align='edge')

pl.title("Execution time of implementations of Image Invert+Blur application")
pl.xlabel("Implementation")
pl.ylabel("Execution time (s)")

pl.gca().set_xticks(x + w/2)
pl.gca().set_xticklabels([PRETTY[l] for l in IMPLS])

pl.savefig(sys.argv[2], bbox_inches='tight')
pl.show()
