import sys
import pandas as pd
import matplotlib.pyplot as plt

d = pd.read_csv(sys.argv[1])
d = d[(d['mesh'] == 8192) & (d['rank'] == 0)]
d = d.sort_values('ranks')

d['dsl_s'] = d['setup_s'] + d['solve_s']

d_theta = d[(d['cluster'] == 'theta') & (d['ranks_per_node'] == 24)]
print(d[d['cluster'] == 'summit'])
d_summit = d[(d['cluster'] == 'summit') & ((d['ranks_per_node'] == 40) | (d['ranks_per_node'] == 42 ))]
print(d_theta)
print(d_summit)

fig = plt.figure(figsize=(5.5, 5))

#fig, ax_theta = plt.subplots()
ax_theta = plt.gca()
ln_theta = ax_theta.plot(d_theta['ranks'], d_theta['dsl_s'], label='Theta (24 ranks/node)',
        marker='o', color='blue')
ax_theta.set_ylabel("Execution Time on Theta (s)")

ax_summit = ax_theta.twinx()

ln_summit = ax_summit.plot(d_summit['ranks'], d_summit['dsl_s'], label='Summit (42 ranks/node)',
        marker='o', color='green')
ax_summit.set_ylabel("Execution Time on Summit (s)")

plt.title("Scaling of CFD DSL code on 8K x 8K 2D mesh")
ax_theta.set_xlabel("Ranks")

lns = ln_theta + ln_summit 
labs = [l.get_label() for  l in lns]
ax_theta.legend(lns, labs)


fig.savefig(sys.argv[2], bbox_inches='tight')
plt.show()
