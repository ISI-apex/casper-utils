# no hashbang on purpose, b/c in some cases, must use shell from within prefix

set -e

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

run() {
	echo "$@"
	"$@"
}

NODES=$1

if [[ -n "${NODES}" ]]
then
	TASKS_PER_NODE=2
	MPI_ARGS=(-n $((NODES * TASKS_PER_NODE))
		--map-by ppr:${TASKS_PER_NODE}:node)
else
	MPI_ARGS=(-n 4)
fi

run mpirun ${MPI_ARGS[@]} "${SELF_DIR}"/../apps/mpitest/mpitest
