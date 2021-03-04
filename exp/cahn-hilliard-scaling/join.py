import sys
import pandas as pd

d1 = pd.read_csv(sys.argv[1])
d1['cluster'] = "theta"
d2 = pd.read_csv(sys.argv[2])
d2['cluster'] = "summit"

d = pd.concat([d1, d2])
print(d)
d.to_csv(sys.argv[3])


