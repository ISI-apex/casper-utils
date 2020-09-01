
set -e

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

run() {
	echo "$@"
	"$@"
}


# Test single-node and multi-node (one proc per node)
for nodes in 1 2
do
	if [[ "${nodes}" -gt 1 ]]
	then
		MPI_ARGS=(--map-by node)
	else
		MPI_ARGS=()
	fi

	for solver in mumps superlu_dist pastix
	do
		for nproc in 1 ${nodes}
		do
			MPI_ARGS_LOC=(${MPI_ARGS[@]} -n "${nproc}")

			run mpirun ${MPI_ARGS_LOC[@]} \
				python "${SELF_DIR}"/../apps/firedrake/matrix_free/stokes-casper.py 64 $solver 0 1
			run mpirun ${MPI_ARGS_LOC[@]} \
				python "${SELF_DIR}"/../apps/fenics/cavity/demo_cavity.py 64 $solver 0 1

			if [[ "$solver" = "superlu_dist" ]]
			then
				eselect superlu_dist set superlu_dist_cuda
			fi

			run mpirun ${MPI_ARGS_LOC[@]} \
				python "${SELF_DIR}"/../apps/firedrake/matrix_free/stokes-casper.py 64 $solver 1 1
			run mpirun ${MPI_ARGS_LOC[@]} \
				python "${SELF_DIR}"/../apps/fenics/cavity/demo_cavity.py 64 $solver 1 1

			if [[ "$solver" = "superlu_dist" ]]
			then
				eselect superlu_dist set superlu_dist
			fi
		done
	done
done
