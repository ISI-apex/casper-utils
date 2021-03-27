#!/bin/bash

set -e
set -x
set -o pipefail

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

PPATH=$1
if [ -z "${PPATH}" ]
then
	echo "ERROR: prefix name not specified as argument" 1>&2
	exit 1
fi
PPATH=$(realpath "${PPATH}")
PROFILE=$2
if [[ -z "${PROFILE}" ]]
then
	echo "ERROR: usage: $0 prefix_path profile" 1>&2
	exit 1
fi

LOGDIR="${PPATH}/var/log/prefix"
mkdir -p "${LOGDIR}"
tstamp=$(date +%Y%m%d%H%M%S)

if type -p nice 2>/dev/null 1>/dev/null
then
	NICE="nice -n 19"
else
	NICE=""
fi

echo "$(basename $0): host $(hostname) procs ${NPROC} tmpdir ${TMPDIR}"
env > "${LOGDIR}"/gpref-${tstamp}.env

${NICE} ${SELF_DIR}/gpref-sys.sh "${PPATH}" "${PROFILE}" 2>&1 | tee ${LOGDIR}/gpref-sys-${tstamp}.log
echo "gpref-sys RC: $?"
${NICE} ${SELF_DIR}/gpref-profile.sh "${PPATH}" "${PROFILE}" 2>&1 | tee ${LOGDIR}/gpref-profile-${tstamp}.log
echo "gpref-profile RC: $?"
