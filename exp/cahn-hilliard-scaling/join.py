import sys
import argparse
import pandas as pd

parser = argparse.ArgumentParser(
    description="Join datasets, creating an identifier column")
parser.add_argument('datasets', nargs='*',
        help="A pair of arguments for each dataset to be joined: name input_file")
parser.add_argument('--output', '-o', required=True,
        help="Name of output file where to save joined dataset")
parser.add_argument('--column', '-c', required=True,
        help="Name of column to create with identifier for each joined dataset")
args = parser.parse_args()

d = pd.DataFrame()
for i in range(0, len(args.datasets), 2):
    d1 = pd.read_csv(args.datasets[i + 1])
    d1[args.column] = args.datasets[i]
    d = pd.concat([d, d1])

print(d)
d.to_csv(args.output)

