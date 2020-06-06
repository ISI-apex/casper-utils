#SOLVERS=(mumps superlu_dist pastix)
SOLVERS=(pastix)

run() {
	echo "$@"
	"$@"
}

use_gpu=$1

for solver in ${SOLVERS[@]}
do
	(

	if [[ "${solver}" = "superlu_dist" ]]
	then
		flock -x 200 || exit 1
		echo "LOCK ACQUIRED"
	fi
	
	#meshes=(64 128 192 256 320 384)
	meshes=(64 128 192 256 320)
	if [[ "${solver}" != "pastix" ]]
	then
		#meshes+=(512 768 1024)
		meshes+=(384 512 768 1024)
	fi

	for m in "${meshes[@]}"
	do
		gpus=(0)

		if [[ -n "${use_gpu}" && "${solver}" != "mumps" ]]
		then
			gpus+=(1)
		fi

		for gpu in "${gpus[@]}"
		do

			if [[ "${solver}" = "superlu_dist" ]]
			then
				eselect superlu_dist set $((gpu+1))
			fi
			run python stokes-casper.py $m $solver $gpu 1
		done
	done

	) 200>/scratch/acolin/casper/exp/jobs/locks/pp.job.lock
done
