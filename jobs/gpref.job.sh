#!/bin/bash

set -e

# set env var BARE to non-zero value if you just want a prefix
# configured with CASPER overlay, but do not want to build the numerical
# libraries.

# export because the nested scripts called below need it
export SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CASPER_UTILS=$(realpath ${SELF_DIR}/..)

export DIST_PATH=${CASPER_UTILS}/distfiles
export OVERLAY_PATH=${CASPER_UTILS}/ebuilds
export FILES_PATH=${CASPER_UTILS}/jobs/gpref
export OFFLINE_MODE=1

# for constraint() function
source ${CASPER_UTILS}/bin/pscommon.sh

PPATH=$1
if [ -z "${PPATH}" ]
then
	echo "ERROR: prefix name not specified as argument" 1>&2
	exit 1
fi
PPATH=$(realpath "${PPATH}")
PROFILE=$2
CLUSTER=$3
ARCH=$4
if [[ -z "${PROFILE}" || -z "${CLUSTER}" || -z "${ARCH}" ]]
then
	echo "ERROR: usage: $0 prefix_path profile cluster arch" 1>&2
	exit 1
fi

LOGDIR="${PPATH}/var/log/prefix"
mkdir -p "${LOGDIR}"

# Memory limit of 0 means use all avaialable memory on the node.
node_info "${CLUSTER}" "${ARCH}"
ARGS+=(--nodes=1 --mem=0 --ntasks=${MIN_CORES} "--constraint=${FEAT}")

# Split jobs because on USC HPCC max limit for a single job is 24h

qjob() {
	echo "$@"
	local out=$("$@")
	JOBID=$(echo "$out" | sed 's/^Submitted batch job \([0-9]\+\)$/\1/')
	[ -n "$JOBID" ] || return 1
	echo "Submitted job: ID ${JOBID}"
}

tstamp=$(date +%Y%m%d%H%M%S)

# Actual time: ~15 hours (but leave margin)
qjob sbatch "${ARGS[@]}" --time 23:59:00 \
	--output="${LOGDIR}"/gpref-${tstamp}.out \
	--error="${LOGDIR}"/gpref-${tstamp}.err \
	${SELF_DIR}/gpref-sys.sh "${PPATH}"

# Actual time: ~18 hours (but leave margin)
qjob sbatch --dependency=afterok:$JOBID \
	"${ARGS[@]}" --time 23:59:00 \
	--output="${LOGDIR}"/gpref-profile-${tstamp}.out \
	--error="${LOGDIR}"/gpref-profile-${tstamp}.err \
	${SELF_DIR}/gpref-profile.sh "${PPATH}" "${PROFILE}"
