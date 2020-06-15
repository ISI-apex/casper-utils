import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np
from matplotlib import rc

# font
rc('font', **{'family': 'serif', 'serif': ['Computer Modern']})
rc('text', usetex=True)
# figure size
plt.figure(figsize=(15,8))
# style
sns.set(style="ticks", font_scale=2, font='text.usetex')

# read data
df = pd.read_csv("result_plot_speedup.csv")
# set labels
ax = sns.barplot(x="mesh_size", y="speedup", hue='shape', data=df)
#ax.set_title('Blur_3x3 with 2^15 input')
ax.set_xlabel('input mesh size')
ax.set_ylabel('speedup')

handles, labels = ax.get_legend_handles_labels()
ax.legend(handles=handles[0:], labels=labels[0:])

# plot
for line in range(0,6):
     ax.text(line-0.2, df.speedup[line]+0.05, df.speedup[line], horizontalalignment='center', 
     size='medium', color='black')
        
for line in range(6,12):
     ax.text(line-5.8, df.speedup[line]+0.05, df.speedup[line], horizontalalignment='center', 
     size='medium', color='black')

plt.show()
