# This is a separate script (not in Makefile) because it is spawned by mpirun.

# Set the compiler vars (esp. CCVER) to prevent firedrake
# from sniffing compiler version (which involves subprocess,
# which forks, but fork breaks uGNI transport in OpenMPI).

BENCH_DIR=../../apps/firedrake-bench

CXX=gcc CC=gcc CCVER=$(gcc -dumpversion | cut -d. -f-2) \
	OMP_NUM_THREADS=${OMP_NUM_THREADS} \
	exec python $(realpath ${BENCH_DIR}/cahn_hilliard/firedrake_cahn_hilliard_bare.py) "$@"
