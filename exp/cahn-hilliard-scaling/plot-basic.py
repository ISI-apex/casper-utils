import argparse
import pandas as pd
import matplotlib.pyplot as plt

def csv_int_list(s):
    return [int(n) for n in s.split(",")]

parser = argparse.ArgumentParser(
    description="Plot mesh distribution time and total time")
parser.add_argument('dataset',
        help="Input file with data (CSV)")
parser.add_argument('figure',
        help="Output file with plot (extension determines format, e.g. .pdf)")
parser.add_argument('--mesh', type=int, required=True,
        help="Mesh size for which to plot data")
parser.add_argument('--tpn', type=csv_int_list, required=True,
        help="Ranks-per-node values which to include (comma-separated)")
parser.add_argument('--timesteps', type=int, required=True,
        help="Timestep count for which to plot data")
args = parser.parse_args()

#show_cols = ['cluster', 'mesh', 'ranks_per_node', 'timesteps', 'total_s']
show_cols = ['mesh', 'ranks_per_node', 'timesteps', 'total_s']

d = pd.read_csv(args.dataset)
d = d[(d['mesh'] == args.mesh) & (d['timesteps'] == args.timesteps) & (d['rank'] == 0)]
d = d.sort_values('ranks')

d['dsl_s'] = d['setup_s'] + d['solve_s']

def calc_tpn_cond(tpns):
    assert len(tpns) > 0
    tpn_cond = d['ranks_per_node'] == tpns[0]
    for i in range(1, len(tpns)):
        tpn_cond = tpn_cond | (d['ranks_per_node'] == tpns[i])
    return tpn_cond

#d_cluster = d[(d['cluster'] == 'theta') & calc_tpn_cond(args.tpn)]
d_cluster = d[calc_tpn_cond(args.tpn)]
print(d_cluster[show_cols])

fig = plt.figure(figsize=(6.3, 5))
#fig, ax_theta = plt.subplots()
ax_theta = plt.gca()

ln_theta = ax_theta.plot(d_cluster['ranks'], d_cluster['mesh_s'],
        label='Distrib.', marker='o')
ln_theta = ax_theta.plot(d_cluster['ranks'], d_cluster['solve_s'],
        label='Solve', marker='o')
ln_theta += ax_theta.plot(d_cluster['ranks'], d_cluster['total_s'], '--',
        label='Total', marker='o')
ax_theta.set_ylabel("Execution Time (s)")

plt.title(f"Time for {args.mesh} x {args.mesh} mesh, " + \
        f"{args.timesteps} timesteps")
ax_theta.set_xlabel("Ranks")

#lns = ln_theta + ln_summit 
#labs = [l.get_label() for  l in lns]
#ax_theta.legend(lns, labs, loc=(0.35, 0.75))
ax_theta.legend(loc=0)

ax_theta.set_ylim(ymin=0)

fig.savefig(args.figure, bbox_inches='tight')
plt.show()
