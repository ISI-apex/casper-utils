
run() {
	echo "$@"
	"$@"
}

for solver in mumps superlu_dist
do
	for nproc in 1 2
	do
		run mpirun -n $nproc python ../../apps/firedrake/matrix_free/stokes-casper.py 64 $solver 0 1
		run mpirun -n $nproc python ../../apps/firedrake/matrix_free/stokes-casper.py 64 $solver 1 1
	done
done
