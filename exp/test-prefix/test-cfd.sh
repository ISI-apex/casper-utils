# no hashbang on purpose, b/c in some cases, must use shell from within prefix

set -e

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

run() {
	echo "$@"
	"$@"
}

GPU=$1

SOLVERS=(mumps superlu_dist pastix)
declare -A FRAMEWORKS
FRAMEWORKS[firedrake]=1
# FEniCS (DOLFIN) is not built in the prefix by default
#FRAMEWORKS[fenics]=1


# Test single-node and multi-node (one proc per node)
for nodes in 1 2
do
	if [[ "${nodes}" -gt 1 ]]
	then
		MPI_ARGS=(--map-by node)
	else
		MPI_ARGS=()
	fi

	for solver in ${SOLVERS[@]}
	do
		for nproc in 1 ${nodes}
		do
			MPI_ARGS_LOC=(${MPI_ARGS[@]} -n "${nproc}")

			if [[ -n "${FRAMEWORKS[firedrake]}" ]]
			then
				run mpirun ${MPI_ARGS_LOC[@]} \
					python "${SELF_DIR}"/../apps/firedrake/matrix_free/stokes-casper.py 64 $solver 0 1
			fi
			if [[ -n "${FRAMEWORKS[fenics]}" ]]
			then
				run mpirun ${MPI_ARGS_LOC[@]} \
					python "${SELF_DIR}"/../apps/fenics/cavity/demo_cavity.py 64 $solver 0 1
			fi

			if [[ -n "${GPU}" ]]
			then
				if [[ "$solver" = "superlu_dist" ]]
				then
					eselect superlu_dist set superlu_dist_cuda
				fi

				if [[ -n "${FRAMEWORKS[firedrake]}" ]]
				then
					run mpirun ${MPI_ARGS_LOC[@]} \
						python "${SELF_DIR}"/../apps/firedrake/matrix_free/stokes-casper.py 64 $solver 1 1
				fi
				if [[ -n "${FRAMEWORKS[fenics]}" ]]
				then
					run mpirun ${MPI_ARGS_LOC[@]} \
						python "${SELF_DIR}"/../apps/fenics/cavity/demo_cavity.py 64 $solver 1 1
				fi

				if [[ "$solver" = "superlu_dist" ]]
				then
					eselect superlu_dist set superlu_dist
				fi
			fi
		done
	done
done
