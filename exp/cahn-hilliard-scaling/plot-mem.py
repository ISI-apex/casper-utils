import sys
import pandas as pd
import matplotlib.pyplot as plt

d = pd.read_csv(sys.argv[1])
d = d[d['cluster'] == 'theta']
d = d[d['rank'] == 0]
d = d[d['mesh'] >= 4096]

for g, d_g in d.groupby('mesh'):
    d_g = d_g.sort_values('ranks')
    
    mem = d_g['mesh_peakmem_mb'] / 1024; # to GB
    print("mesh", g)
    print(d_g[['mesh', 'ranks', 'mesh_peakmem_mb', 'cluster']])
    plt.plot(d_g['ranks'], mem, label=f"Mesh {g}x{g}", marker='o')

plt.title("Memory consumption during mesh distribution")
plt.xlabel("Ranks")
plt.ylabel("Memory used by master rank (GB)")
plt.legend(loc=(0.6, 0.2))

plt.savefig(sys.argv[2], bbox_inches='tight')
plt.show()
