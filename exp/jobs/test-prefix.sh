
SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

run() {
	echo "$@"
	"$@"
}

for solver in mumps superlu_dist pastix
do
	for nproc in 1 2
	do
		run mpirun -n $nproc python "${SELF_DIR}"/../apps/firedrake/matrix_free/stokes-casper.py 64 $solver 0 1

		if [[ "$solver" = "superlu_dist" ]]
		then
			eselect superlu_dist set superlu_dist_cuda
		fi
		run mpirun -n $nproc python "${SELF_DIR}"/../apps/firedrake/matrix_free/stokes-casper.py 64 $solver 1 1

		if [[ "$solver" = "superlu_dist" ]]
		then
			eselect superlu_dist set superlu_dist
		fi
	done
done
