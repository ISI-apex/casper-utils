import pylab as pl
import pandas as pd

d = pd.read_csv('pastix-gpu.csv')
d = d.set_index('mesh')

d['tot_cpu_time_sec'] = d['tot_cpu_time_m']*60 + d['tot_cpu_time_s']
d['tot_gpu_time_sec'] = d['tot_gpu_time_m']*60 + d['tot_gpu_time_s']

d[['tot_cpu_time_sec','tot_gpu_time_sec']].plot(marker='o')
pl.title("Cavity in Firedrake/PyOP2 with PaStiX solver (total time)")
pl.ylabel("Total execution Time (s)")
pl.xlabel("Mesh dimension")
pl.savefig('pastix-gpu-total.pdf', bbox_inches='tight')

d[['cpu_time_to_solve','gpu_time_to_solve']].plot(marker='o')
pl.title("Cavity in Firedrake/PyOP2 with PaStiX solver (solve time)")
pl.ylabel("Time to solve (s)")
pl.xlabel("Mesh dimension")
pl.savefig('pastix-gpu-solve.pdf', bbox_inches='tight')

d[['cpu_factorize','gpu_factorize']].plot(marker='o')
pl.title("Cavity in Firedrake/PyOP2 with PaStiX solver (factorize time)")
pl.ylabel("Time to factorize (s)")
pl.xlabel("Mesh dimension")
pl.savefig('pastix-gpu-factorize.pdf', bbox_inches='tight')

d[['cpu_mflops','gpu_mflops']].plot(marker='o')
pl.title("Cavity in Firedrake/PyOP2 with PaStiX solver (Solve Mflop/s)")
pl.ylabel("Solve Mflop/s")
pl.xlabel("Mesh dimension")
pl.savefig('pastix-gpu-mflops.pdf', bbox_inches='tight')

pl.show()
