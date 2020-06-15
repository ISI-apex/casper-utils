
# coding: utf-8

import pandas as pd
attributes = ['runtime','mesh','np','th','cons']
df = pd.read_csv('result.csv', sep=',', names=attributes)
df = df.drop_duplicates(['mesh','np','th'])
df.to_csv('out.csv', index=False)