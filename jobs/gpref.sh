#!/bin/bash

set -e

# set env var BARE to non-zero value if you just want a prefix
# configured with CASPER overlay, but do not want to build the numerical
# libraries.

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CASPER_UTILS=$(realpath ${SELF_DIR}/..)

export DIST_PATH=${CASPER_UTILS}/distfiles
export OVERLAY_PATH=${CASPER_UTILS}/ebuilds
export TMP_HOME=/tmp

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

${SELF_DIR}/gpref-sys.sh "${PPATH}"
${SELF_DIR}/gpref-profile.sh "${PPATH}" "${PROFILE}"
