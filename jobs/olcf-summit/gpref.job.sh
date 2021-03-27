#!/bin/bash

set -e

ACCOUNT=csc436

PPATH=$1
PROFILE=$2
if [ -z "${PPATH}" ]
then
	echo "ERROR: prefix name not specified as argument" 1>&2
	exit 1
fi
PPATH=$(realpath "${PPATH}")
if [[ -z "${PROFILE}" ]]
then
	echo "ERROR: usage: $0 prefix_path profile" 1>&2
	exit 1
fi

export SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
JOBS_DIR=$(realpath ${SELF_DIR}/..)

LOGDIR="${PPATH}/var/log/prefix"
mkdir -p "${LOGDIR}"

tstamp=$(date +%Y%m%d%H%M%S)

# Something in the default environment breaks loader, so keep only some vars,
# besides the some defaults
EXTRA_ENV=(
	LSB_JOBID
	__LSF_JOB_TMPDIR__
)

exec bsub "${ARGS[@]}" -P "${ACCOUNT}" \
	-nnodes 1 -W 24:00 -q killable \
	-J "gpref-${tstamp}" \
	-o "${LOGDIR}/gpref-${tstamp}.%J.log" \
	jsrun -n 1 --cpu_per_rs ALL_CPUS --bind none \
	${JOBS_DIR}/filterenv.sh "${EXTRA_ENV[@]}" -- \
	${JOBS_DIR}/gpref.sh "${PPATH}" "${PROFILE}"
