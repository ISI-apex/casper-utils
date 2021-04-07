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
parser.add_argument('--theta-tpn', type=csv_int_list, required=True,
        help="Ranks-per-node values which to include " +
            "from Theta cluster (comma-separated)")
parser.add_argument('--summit-tpn', type=csv_int_list, required=True,
        help="Ranks-per-node values which to include " +
            "from Summit cluster (comma-separated)")
args = parser.parse_args()

show_cols = ['cluster', 'mesh', 'ranks_per_node', 'total_s']

d = pd.read_csv(args.dataset)
d = d[(d['mesh'] == args.mesh) & (d['rank'] == 0)]
d = d.sort_values('ranks')

d['dsl_s'] = d['setup_s'] + d['solve_s']

def calc_tpn_cond(tpns):
    assert len(tpns) > 0
    tpn_cond = d['ranks_per_node'] == tpns[0]
    for i in range(1, len(tpns)):
        tpn_cond = tpn_cond | (d['ranks_per_node'] == tpns[i])
    return tpn_cond

d_theta = d[(d['cluster'] == 'theta') & calc_tpn_cond(args.theta_tpn)]
d_summit = d[(d['cluster'] == 'summit') & calc_tpn_cond(args.summit_tpn)]
print(d_theta[show_cols])
print(d_summit[show_cols])

fig = plt.figure(figsize=(6.3, 5))
#fig, ax_theta = plt.subplots()
ax_theta = plt.gca()

ln_theta = ax_theta.plot(d_theta['ranks'], d_theta['mesh_s'],
        label='Dist. Theta',
        marker='o', color='blue')
ln_theta += ax_theta.plot(d_theta['ranks'], d_theta['total_s'], '--',
        label='Total Theta',
        marker='o', color='blue')
ax_theta.set_ylabel("Execution Time on Theta (s)")

ax_summit = ax_theta.twinx()

ln_summit = ax_summit.plot(d_summit['ranks'], d_summit['mesh_s'],
        label='Dist. Summit',
        marker='o', color='green')
ln_summit += ax_summit.plot(d_summit['ranks'], d_summit['total_s'], '--',
        label='Total Summit',
        marker='o', color='green')
ax_summit.set_ylabel("Execution Time on Summit (s)")

plt.title(f"Time to distribute {args.mesh} x {args.mesh} 2D mesh")
ax_theta.set_xlabel("Ranks")

lns = ln_theta + ln_summit 
labs = [l.get_label() for  l in lns]
ax_theta.legend(lns, labs, loc=(0.1, 0.1))

ax_theta.set_ylim(ymin=0)
ax_summit.set_ylim(ymin=0)


fig.savefig(args.figure, bbox_inches='tight')
plt.show()
