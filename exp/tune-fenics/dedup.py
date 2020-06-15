
# coding: utf-8

import sys
import pandas as pd

if len(sys.argv) != 3:
    print("USAGE: %s <IN_FILE> <OUT_FILE>" % sys.argv[0], file=sys.stderr)
    sys.exit(1)

IN_FILE=sys.argv[1]
OUT_FILE=sys.argv[2]

attributes = ['runtime','mesh','np','th','cons']
df = pd.read_csv(IN_FILE, sep=',', names=attributes)
df = df.drop_duplicates(['mesh','np','th'])
df.to_csv(OUT_FILE, index=False)
