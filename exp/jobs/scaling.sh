#!/bin/bash

PREF=/scratch/acolin/casper/gpref/gp-amd64

time_limit=$1
if [ -z "${time_limit}" ]
then
	echo "ERROR: usage: $0 time_limit" 1>&2
	exit 1
fi

if [ -z "${NTASKS}" ]
then
	echo "ERROR: env var not set: NTASKS" 1>&2
	exit 1
fi
if [ -z "${SOLVERS}" ]
then
	echo "ERROR: env var not set: SOLVERS" 1>&2
	exit 1
fi
if [ -z "${SKIP}" ]
then
	SKIP=0
fi


unpack() {
	echo $@ | sed 's/,/ /g'
}

NTASKS=($(unpack ${NTASKS}))

# [p]sbatch can't deal with spaces in arguments
#SOLVERS=$(echo ${SOLVERS} | sed 's/ /,/g')
#MESHES=$(echo ${MESHES} | sed 's/ /,/g')

# SOLVERS
# NTASKS_PER_NODE

#NTASKS=(1 8 16 32 64 128)
#NTASKS=(1 8 16 32 64)
#NTASKS=(8 16 32)


# NTASKS_PER_NODE=1
# MEM_PER_TASK=60G

#NTASKS=(16)
#NTASKS=(4 8)
#NTASKS_PER_NODE=4
#NTASKS=(8)

#NTASKS_PER_NODE=8
#MEM_PER_TASK=7G

MEM_PER_NODE=60

run() {
	echo "$@"
	"$@"
}

for ntasks in ${NTASKS[@]}
do
	if [[ "$ntasks" -le $NTASKS_PER_NODE ]]
	then
		nodes=1
	else
		nodes=$((ntasks / NTASKS_PER_NODE))
	fi
	mem_per_task=$((MEM_PER_NODE / NTASKS_PER_NODE))
	dir="s-N${NTASKS_PER_NODE}-$(echo S${SOLVERS}-M${MESHES} | sed 's/ /,/g')"
	name=${dir}-T${ntasks}
	mkdir -p ${dir}

	run env NONBLOCK=1 \
		psbatch $PREF sandybridge "" ${mem_per_task}G \
			$nodes $ntasks ${time_limit} \
			--job-name=${name} \
			--ntasks-per-node=$NTASKS_PER_NODE \
			--output=${dir}/${name}.out \
			--error=${dir}/${name}.err \
			jobs/scaling.job.sh "$SKIP" "$NTASKS_PER_NODE" "$ntasks" "$SOLVERS" "$MESHES"
done
