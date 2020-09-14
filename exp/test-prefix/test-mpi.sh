# no hashbang on purpose, because need to use shell from within prefix

set -e

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

run() {
	echo "$@"
	"$@"
}

run mpirun -n 4 --map-by ppr:2:node "${SELF_DIR}"/../apps/mpitest/mpitest
