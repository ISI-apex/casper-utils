# "$SKIP" "$NTASKS_PER_NODE" "$ntasks" "$SOLVERS" "$MESHES"

unpack() {
	echo $@ | sed 's/,/ /g'
}

SKIP="$1"
NPROC_PER_NODE="$2"
NPROC="$3"
SOLVERS=($(unpack $4))
MESHES=($(unpack $5))

#if [ -z "${NPROC_PER_NODE}" ]
#then
#	echo "ERROR: env var not set: NPROC_PER_NODE" 1>&2
#	exit 1
#fi
#if [ -z "${NPROC}" ]
#then
#	echo "ERROR: env var not set: NPROC" 1>&2
#	exit 1
#fi
#if [ -z "${SOLVERS}" ]
#then
#	echo "ERROR: env var not set: SOLVERS" 1>&2
#	exit 1
#fi
#SOLVERS=(${SOLVERS})
#if [ -z "${MESHES}" ]
#then
#	echo "ERROR: env var not set: MESHES" 1>&2
#	exit 1
#fi
#MESHES=(${MESHES})

#SOLVERS=(mumps superlu_dist pastix)
#SOLVERS=(superlu_dist pastix)
#SOLVERS=(mumps)
gpu=0

run() {
	echo "$@"
	"$@"
}

echo SOLVERS ${SOLVERS[@]}
echo MESHES ${MESHES[@]}

for solver in ${SOLVERS[@]}
do
	for m in "${MESHES[@]}"
	do
		if [[ "$SKIP" -eq 1 ]]
		then
			if [[ "${solver}" = "pastix" && "${m}" -gt 256 ]]
			then
				echo "SKIPPED: ${solver} ${m}: pastix can't handle mesh > 256"
				continue
			fi
			if [[ "${solver}" = "superlu_dist" && "${m}" -gt 512 ]]
			then
				echo "SKIPPED: ${solver} ${m}: superlu_dist can't handle mesh > 512"
				continue
			fi
		fi
		#run mpirun -n $NPROC -N $NPROC_PER_NODE python apps/firedrake/matrix_free/stokes-casper.py $m $solver $gpu 1
		run mpirun -n $NPROC -N $NPROC_PER_NODE python apps/fenics/cavity/demo_cavity.py $m $solver $gpu 1
	done
done
