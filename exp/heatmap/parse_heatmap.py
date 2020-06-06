import sys
import re

#nproc_nthread_pairs = [(int(x), int(y)) for x,y in [a.split() for a in sys.argv[1:]]]

PROCS=[1,2,4,6,8,12,16,24,32]
THREADS=[1,2,4,6,8,12,16,24,32]
NUM_TRIALS=2

nproc_nthread_pairs = []
for nproc in PROCS:
    for nthread in THREADS:
        if nproc * nthread > 32:
            continue
        nproc_nthread_pairs.append((nproc, nthread))


print("solver,mesh,nproc,nthread,trial,time")

solver = None
trial = 0
for line in sys.stdin:
    line = line.strip()

    if solver is None:
        m = re.match(r'mpirun\s+.*\s+python\s+\S+.py\s+([0-9]+)\s+(\S+)\s+.*', line)
        if m is not None:
            mesh = m.group(1)
            solver = m.group(2)
            p = 0
            nproc_lines = 0

    m = re.match(r'^Time: ([0-9.]+)', line)
    if m is None:
        continue
    nproc, nthread = nproc_nthread_pairs[p]
    nproc_lines += 1
    if nproc_lines == nproc:

        runtime = float(m.group(1))
        assert mesh is not None
        assert solver is not None
        print(solver, mesh, nproc, nthread, trial, runtime, sep=',')

        if trial == NUM_TRIALS - 1:
            trial = 0
            p += 1
        else:
            trial += 1
        nproc_lines = 0

        if p == len(nproc_nthread_pairs):
            p = 0
            solver = None
