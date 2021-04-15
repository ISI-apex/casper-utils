# no hashbang on purpose, b/c in some cases, must use shell from within prefix

set -e

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

run() {
	echo "$@"
	"$@"
}

die() {
	echo "$@" 1>&2
	exit 1
}

GPU=$1

if [[ -n "${NOLOCAL}" ]]
then
	MAP_BY_SUFFIX=:NOLOCAL
fi

SOLVERS=(mumps superlu_dist pastix)
declare -A FRAMEWORKS
FRAMEWORKS[firedrake]=1
# FEniCS (DOLFIN) is not built in the prefix by default
#FRAMEWORKS[fenics]=1

# Matlab creates files in this dir, and it must not be the $HOME filesystem
# NOTE: if you add/change these, make sure to change then below too
export MPLCONFIGDIR=mpldir
export XDG_CACHE_HOME=cachedir

# Create a persistent PRRTE DVM that spans the whole job allocation, to
# amortize the cost to startup the OpenMPI daemons on each node.
run prte --daemonize
trap "run pterm" EXIT

# TODO: update the above to this when openmpi & co packages are updated
#run prte --report-pid dvm.pid --daemonize
#while [[ ! -f "dvm.pid" ]]
#do
#	echo "Waiting for DVM to startup..."
#	sleep 2
#done
#DVM_PID=$(cat dvm.pid)
#[[  -n "${DVM_PID}" ]] || die "DVM did not create a PID file"
#trap "run pterm --pid ${DVM_PID}" EXIT

# Test single-node and multi-node (one proc per node)
for nodes in 1 2
do
	# TODO: add --pid "${DVM_PID}" (see above)
	MPI_ARGS=(-x MPLCONFIGDIR -x XDG_CACHE_HOME)
	if [[ "${nodes}" -gt 1 ]]
	then
		MPI_ARGS+=(--map-by node${MAP_BY_SUFFIX})
	else
		MPI_ARGS+=(--map-by slot${MAP_BY_SUFFIX})
	fi

	for solver in ${SOLVERS[@]}
	do
		for nproc in 1 ${nodes}
		do
			MPI_ARGS_LOC=(${MPI_ARGS[@]} -n "${nproc}")

			if [[ -n "${FRAMEWORKS[firedrake]}" ]]
			then
				run prun ${MPI_ARGS_LOC[@]} \
					python "${SELF_DIR}"/../apps/firedrake/matrix_free/stokes-casper.py 64 $solver 0 1
			fi
			if [[ -n "${FRAMEWORKS[fenics]}" ]]
			then
				run prun ${MPI_ARGS_LOC[@]} \
					python "${SELF_DIR}"/../apps/fenics/cavity/demo_cavity.py 64 $solver 0 1
			fi

			if [[ -n "${GPU}" ]]
			then
				if [[ "$solver" = "superlu_dist" ]]
				then
					run eselect superlu_dist set superlu_dist_cuda
				fi

				if [[ -n "${FRAMEWORKS[firedrake]}" ]]
				then
					run prun ${MPI_ARGS_LOC[@]} \
						python "${SELF_DIR}"/../apps/firedrake/matrix_free/stokes-casper.py 64 $solver 1 1
				fi
				if [[ -n "${FRAMEWORKS[fenics]}" ]]
				then
					run prun ${MPI_ARGS_LOC[@]} \
						python "${SELF_DIR}"/../apps/fenics/cavity/demo_cavity.py 64 $solver 1 1
				fi

				if [[ "$solver" = "superlu_dist" ]]
				then
					run eselect superlu_dist set superlu_dist
				fi
			fi
		done
	done
done
