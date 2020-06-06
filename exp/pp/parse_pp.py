#!/usr/bin/python

import sys
import re
import argparse

# EXEC TIME (sec): mesh 384 solver pastix threads 1 gpu 1 : 259.4336075782776

parser = argparse.ArgumentParser(
        description="Parse log from PP experiment into CSV")
parser.add_argument("--gpu", required=True, help="GPU model")
parser.add_argument("--cpu", required=True, help="CPU model")
args = parser.parse_args()

print("mesh,solver,pe,threads,runtime")

for line in sys.stdin:
    line = line.strip()
    m = re.match(r'^EXEC TIME \(sec\): mesh ([0-9]+) solver (\S+) threads ([0-9]+) gpu ([0-9]+) : ([0-9.]+)', line)
    if m is None:
        continue
    mesh = m.group(1)
    solver = m.group(2)
    threads = m.group(3)
    gpu = m.group(4)
    runtime = m.group(5)

    if int(gpu) == 1:
        pe = args.gpu
    else:
        pe = args.cpu

    print(mesh, solver, pe, threads, runtime, sep=',')
