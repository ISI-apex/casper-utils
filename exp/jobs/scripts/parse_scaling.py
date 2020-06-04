#!/usr/bin/python

import sys
import re
import argparse

# su-scaling-8.out:EXEC TIME (sec): mesh 512 solver superlu_dist threads 1 gpu 0 : 169.87484693527222

parser = argparse.ArgumentParser(
        description="Parse log from scaling experiment into CSV")
parser.add_argument("--ntasks_per_node", required=True, type=int)
args = parser.parse_args()

print("mesh,solver,ntasks,ntasks_per_node,threads,runtime")

seen = {}

for line in sys.stdin:
    line = line.strip()
    m = re.match(r'^[^:]+-([0-9]+).out:EXEC TIME \(sec\): mesh ([0-9]+) solver (\S+) threads ([0-9]+) gpu ([0-9]+) : ([0-9.]+)', line)
    if m is None:
        continue
    ntasks = m.group(1)
    mesh = m.group(2)
    solver = m.group(3)
    threads = m.group(4)
    gpu = m.group(5)
    runtime = m.group(6)

    if solver in seen and mesh in seen[solver] and ntasks in seen[solver][mesh]:
        continue
    else:
        if not solver in seen:
            seen[solver] = {}
        if not mesh in seen[solver]:
            seen[solver][mesh] = {}
        seen[solver][mesh][ntasks] = True

    print(mesh, solver, ntasks, args.ntasks_per_node, threads, runtime, sep=',')
