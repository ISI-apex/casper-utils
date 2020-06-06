import sys
import os
import pylab as pl
import pandas as pd
import seaborn as sb
import numpy as np

fname = sys.argv[1]
#mesh = int(sys.argv[2])
bname = os.path.splitext(fname)[0]

d = pd.read_csv(fname)
print(d)

#d = d.astype({'mesh': 'int32', 'nproc': 'int32', 'nthread': 'int32'})

solvers_pretty = {
    'mumps': 'MUMPS',
    'superlu_dist': 'SuperLU_DIST',
    'pastix': 'PaStiX',
}

## outliers
#d[d['time'] > 1000] = np.nan

dg_mesh = d.groupby('mesh')['time']
print(dg_mesh.min())
print(dg_mesh.max())
#sys.exit(0)
vmin = dg_mesh.min()
vmax = dg_mesh.max()

d = d.groupby(['solver', 'mesh', 'nproc', 'nthread'])['time'].mean()
d = d.unstack(['solver', 'mesh', 'nproc'])
print(d)
#sys.exit(0)

#d = d.pivot_table(columns=['solver', 'mesh', 'nproc', 'trial'], index='nthread', values='time')


print(d.index)
idx_name = d.index.name
d.index = d.index.astype('int32')
d.index.name = idx_name
print(d.index)
print(d.columns)
#d['mumps'].columns = d['mumps'].columns.astype('int32')
print(d.columns)
d.columns = pd.MultiIndex.from_tuples([(s, int(x), int(y)) for s, x, y in d.columns],
        names=d.columns.names)
print(d.columns)



#sys.exit(0)
#f = pl.figure()
x = 0
y = 0
solvers = {}
for solver, mesh, nproc in d.columns:
    if solver not in solvers:
        x += 1
        y = 0
        solvers[solver] = True
        meshes = {}
    if mesh not in meshes:
        #ax = pl.subplot(len(d.columns), x + 1, y + 1)
        #sb.heatmap(d[solver][mesh], ax=ax)

        f = pl.figure()
        sb.heatmap(d[solver][mesh], vmin=vmin[mesh], vmax=vmax[mesh])
        pl.xlabel("Number of Processes (MPI ranks)")
        pl.ylabel("Number of OpenMP threads")
        solver_f = solvers_pretty[solver]
        pl.title(f"Runtime for {solver_f} on mesh {mesh}x{mesh}")

        figname = f'{bname}-{solver}-{mesh}'
        f.savefig(figname + '.pdf', bbox_inches='tight')
        f.savefig(figname + '.svg', bbox_inches='tight')

        y += 1
        meshes[mesh] = True

#f.savefig(bname + '.pdf', bbox_inches='tight')
#f.savefig(bname + '.svg', bbox_inches='tight')

pl.show()
