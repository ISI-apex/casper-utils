import matplotlib.pyplot as plt
from matplotlib import rc
import seaborn as sns
import pandas as pd
import numpy as np

# font 
rc('font', **{'family': 'serif', 'serif': ['Computer Modern']})
rc('text', usetex=True)
# figure size
plt.figure(figsize=(15,8))
# style
sns.set(style="ticks", font_scale=3.5, font='text.usetex')

# read data
df = pd.read_csv("result_plot.csv")
# set labels
ax = sns.lineplot(x="mesh_size", y="runtime", hue="shape", 
                  style='shape',
                  markers=True, data=df, linewidth=5, markersize=15)
#ax.set_title('Blur_3x3 with 2^15 input')

ax.lines[0].set_linestyle("None")
ax.lines[3].set_linestyle("None")
#customize: ax.lines[1].set_marker("^")
ax.set_xlabel('input mesh size')
ax.set_ylabel('execution time (s)')

# uncomment the following two lines for a log scale plot
#ax.set(yscale="log")
#ax.set_ylim([1e-2, 1000])


#customize: ax.legend().get_lines()[3].set_linestyle("None")
handles, labels = ax.get_legend_handles_labels()
handles[1].set_linestyle("None")
handles[4].set_linestyle("None")
for handle in handles:
    handle.set_markersize(15)
    handle.set_linewidth(3)
#customize: handles[2].set_marker("^")
#customize: handles[1].set_linestyle("-")
#customize: handles[2].set_linestyle("--")
ax.legend(handles=handles[1:], labels=labels[1:])

# plot 
plt.show()
