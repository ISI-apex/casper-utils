import sys
import pandas as pd

d = pd.read_csv(sys.argv[1])
d = d[(d['mesh'] >= 4096) & (d['rank'] == 0)]
d.to_csv(sys.argv[2])
