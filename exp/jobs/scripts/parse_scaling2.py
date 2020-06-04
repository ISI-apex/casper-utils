#!/usr/bin/python

import sys
import re
import argparse

# su-scaling-8.out:EXEC TIME (sec): mesh 512 solver superlu_dist threads 1 gpu 0 : 169.87484693527222

parser = argparse.ArgumentParser(
        description="Parse log from scaling experiment into CSV")
parser.add_argument("--ntasks_per_node", required=True, type=int)
parser.add_argument("log_file", nargs='+')
args = parser.parse_args()

print("mesh,solver,ntasks,ntasks_per_node,threads,runtime")

seen = {}

re_result = re.compile(r'^EXEC TIME \(sec\): mesh ([0-9]+) solver (\S+) threads ([0-9]+) gpu ([0-9]+) : ([0-9.]+)')

for log_file in args.log_file:
    m = re.match(r'[^:]+-T([0-9]+).out', log_file)
    if m is None:
        print(f"ERROR: cannot parse number of tasks from filename: {log_file}", file=sys.stderr)
        sys.exit(1)
    ntasks = m.group(1)
    log_fd = open(log_file, "r")

    for line in log_fd:
        line = line.strip()
        m = re_result.match(line)
        if m is None:
            continue
        mesh = m.group(1)
        solver = m.group(2)
        threads = m.group(3)
        gpu = m.group(4)
        runtime = m.group(5)

        if solver in seen and mesh in seen[solver] and ntasks in seen[solver][mesh]:
            continue
        else:
            if not solver in seen:
                seen[solver] = {}
            if not mesh in seen[solver]:
                seen[solver][mesh] = {}
            seen[solver][mesh][ntasks] = True

        print(mesh, solver, ntasks, args.ntasks_per_node, threads, runtime, sep=',')
