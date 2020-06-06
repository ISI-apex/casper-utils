
# pastix busy-hangs with nthreads > 1
SOLVERS=(mumps superlu_dist)
MESHES=(128 384)

PROCS=(1 2 4 6 8 12 16 24 32)
THREADS=(1 2 4 6 8 12 16 24 32)
TRIALS=2

run() {
	echo "$@"
	"$@"
}

for mesh in ${MESHES[@]}
do
	for solver in ${SOLVERS[@]}
	do
		for np in ${PROCS[@]}
		do
			for nt in ${THREADS[@]}
			do
				tot_threads=$((${np} * ${nt}))
				if [[ "${tot_threads}" -gt 32 ]]
				then
					continue
				fi
				args=()
				if [[ "${tot_threads}" -gt 16 ]]
				then
					args+=(--use-hwthread-cpus)
					# For some thread values (24), results in some
					# wild 10x slowdown relative to no bind
					#args+=(--bind-to hwthread)
					args+=(--bind-to none)
				else
					args+=(--bind-to core)
				fi
				for trial in $(seq ${TRIALS})
				do
					echo TRIAL ${trial}
					run mpirun --map-by slot:PE=${nt} ${args[@]} --np ${np} python demo_cavity.py ${mesh} ${solver} 0 ${nt}
				done
			done
		done
	done
done
