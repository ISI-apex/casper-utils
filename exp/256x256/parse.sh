find  meas/256x256/mumps/atlas-blas-st/mpi/ -name 'th*.log' -exec grep '^ *\(Process 0: \)\?Elapsed.*(LU solver)' {} + | sed 's/^.*\/mpi\/np\([0-9]\+\)\/th\([0-9]\+\).log:.*time: \([0-9.]\+\),.*/\1,\2,\3/g'
