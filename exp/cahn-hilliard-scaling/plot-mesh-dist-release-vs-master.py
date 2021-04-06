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
parser.add_argument('--release-tpn', type=csv_int_list, required=True,
        help="Ranks-per-node values which to include " +
            "from experiment on release (comma-separated)")
parser.add_argument('--master-tpn', type=csv_int_list, required=True,
        help="Ranks-per-node values which to include " +
            "from expierment on master (comma-separated)")
args = parser.parse_args()

show_cols = ['version', 'mesh', 'ranks_per_node', 'ranks',
        'mesh_s', 'setup_s', 'solve_s', 'total_s']

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

d_release = d[(d['version'] == 'release') & calc_tpn_cond(args.release_tpn)]
d_master = d[(d['version'] == 'master') & calc_tpn_cond(args.master_tpn)]
print(d_release[show_cols])
print(d_master[show_cols])

fig = plt.figure(figsize=(6.3, 5))
#fig, ax_release = plt.subplots()
ax_release = plt.gca()

ln_release = ax_release.plot(d_release['ranks'], d_release['mesh_s'],
        label='Dist. (release)',
        marker='o', color='blue')
ln_release += ax_release.plot(d_release['ranks'], d_release['total_s'], '--',
        label='Total (release)',
        marker='o', color='blue')
ax_release.set_ylabel("Execution time on release version (s)")

#ax_master = ax_release.twinx()
ax_master = ax_release

ln_master = ax_master.plot(d_master['ranks'], d_master['mesh_s'],
        label='Dist. (master)',
        marker='o', color='green')
ln_master += ax_master.plot(d_master['ranks'], d_master['total_s'], '--',
        label='Total (master)',
        marker='o', color='green')
ax_master.set_ylabel("Execution time on master version (s)")

plt.title(f"Time to distribute {args.mesh} x {args.mesh} 2D mesh")
ax_release.set_xlabel("Ranks")

lns = ln_release + ln_master 
labs = [l.get_label() for  l in lns]
ax_release.legend(lns, labs, loc=(0.35, 0.75))

ax_release.set_ylim(ymin=0)
ax_master.set_ylim(ymin=0)

fig.savefig(args.figure, bbox_inches='tight')
plt.show()
