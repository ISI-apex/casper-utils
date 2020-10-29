import pandas as pd
import pylab as pl
import argparse

parser = argparse.ArgumentParser(description="Plot CFD scaling")
parser.add_argument('data_in_file', help="input file with measurements (CSV)")
parser.add_argument('plot_out_file', help="output file with plot (SVG or PDF)")
parser.add_argument('--show', action='store_true',
        help="show plot in X window (interactive mode)")
parser.add_argument('--x-axis', choices=['ranks', 'nodes'], default='ranks',
        help="units of X-axis")
parser.add_argument('--mesh', type=int, default=None,
        help="plot only the given  mesh size")
parser.add_argument('--x-lim-max', type=int, default=None,
        help="upper limit of the X-axis range (ranks)")
args = parser.parse_args()

d = pd.read_csv(args.data_in_file)
d['total_s'] = d['mesh_s'] + d['setup_s'] + d['solve_s']
d = d.sort_values(['mesh', 'ranks', 'ranks_per_node'])

if args.mesh is not None:
    expers = [(args.mesh, 'gres')]
else:
    expers = [(512, 'gres'), (1024, 'gres'), (2048, 'gres'), (3072, 'gres'), (4096, 'gres'), (6144, 'gres')]

steps = ['mesh_s', 'setup_s', 'solve_s', 'total_s']
STEP_NAMES = {
        'mesh_s': ('distribute', 'r'),
        'setup_s': ('assemble', 'orange'),
        'solve_s': ('solve', 'g'),
        'total_s': ('TOTAL', 'k'),
}

if args.mesh is None:
    #pl.figure(figsize=(5.5, 7))
    #figsize=(10, 7)
    figsize=(12, 10)
else:
    figsize=None
pl.figure(figsize=figsize)

ax = None
for i, exper in enumerate(expers):
    mesh, solver = exper
    print(exper)

    if args.mesh is not None:
        cols = 1
    else:
        cols = 2
    ax = pl.subplot(len(expers), cols, 2 * i + 1, sharex=ax)

    de = d[d['mesh'] == mesh]
    ranks = de['ranks']
    nodes = de['ranks'] / de['ranks_per_node']

    print("mesh=", mesh, de['ranks'])
    for step in steps:
        times = de[step] / 62
        step_name = STEP_NAMES[step][0]
        color = STEP_NAMES[step][1]

        if args.x_axis == 'ranks':
            resources = ranks
        elif args.x_axis == 'nodes':
            resources = nodes
        else:
            raise Exception("invalid x-axis unit")

        ax.plot(resources, times,
                label=f'Step: {step_name}', marker='o', color=color)

    if args.mesh is None:
        solve_ax = pl.subplot(len(expers), cols, 2 * i + 1 + 1, sharex=ax)
        solve_times = de['solve_s'] / 60
        step_name = STEP_NAMES['solve_s'][0]
        color = STEP_NAMES['solve_s'][1]

        if args.x_axis == 'ranks':
            resources = ranks
        elif args.x_axis == 'nodes':
            resources = nodes
        else:
            raise Exception("invalid x-axis unit")

        solve_ax.plot(resources, solve_times,
                label=f'Step: {step_name}', marker='o', color=color)

        #ax.set_xlim((16, 384))
        ax.set_xlim((16, 512))
        #ax.set_xlim((16, 768))

    else:
        if args.x_lim_max is not None:
            ax.set_xlim(xmax=args.x_lim_max)

    if args.mesh is not None:
        ax.set_title(f'Mesh: {mesh}x{mesh}')
        extra_ylabel = ''
        legend_i = 0
    else:
        title=f'Mesh: {mesh}x{mesh}'
        extra_ylabel = f'{title}\n'
        legend_i = len(expers) - 1
    ax.set_ylabel(f'{extra_ylabel}Time (min)')

    if i == len(expers) - 1:
        if args.x_axis == 'ranks':
            xlabel = 'Ranks (= physical cores)'
        elif args.x_axis == 'nodes':
            xlabel = 'Nodes'
        ax.set_xlabel(xlabel)
    if i == legend_i:
        ax.legend()
        if args.mesh is None:
            solve_ax.legend()

pl.savefig(args.plot_out_file, bbox_inches='tight')

if args.show:
    pl.show()
