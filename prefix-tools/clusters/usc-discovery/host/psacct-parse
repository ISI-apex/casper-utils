#!/usr/bin/env python3

import sys

fin = sys.stdin

keys = fin.readline().split('|')
job_dicts = []

while fin:
	line = fin.readline()
	if len(line) == 0:
		break
	values = line.split('|')
	job_dict = dict(zip(keys, values))
	job_dicts.append(job_dict)

key_width = max(map(len, keys))

for key in keys:
	print(("%" + str(key_width) + "s") % key, ":", end=' ')
	for job_dict in job_dicts:
		val_width = max(map(len, job_dict.values()))
		print(("%" + str(val_width) + "s") % job_dict[key], end=' ')
	print()
