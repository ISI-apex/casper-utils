import sys
import argparse
import pandas as pd

def csv_int_list(s):
    return [int(n) for n in s.split(",")]

parser = argparse.ArgumentParser(
    description="Filter rows in a dataset")
parser.add_argument('dataset',
        help="File name of the input dataset (CSV)")
parser.add_argument('--output', '-o', required=True,
        help="Name of output file where to save filtered dataset")
parser.add_argument('--mesh', type=csv_int_list,
        help="Mesh sizes to include (comma-separated)")
parser.add_argument('--rank', type=csv_int_list,
        help="Ranks to include (comma-separated)")
args = parser.parse_args()

d = pd.read_csv(args.dataset)

for mesh in args.mesh:
    d = d[(d['mesh'] == mesh)]
for rank in args.rank:
    d = d[(d['rank'] == rank)]

print(d)
d.to_csv(args.output)
