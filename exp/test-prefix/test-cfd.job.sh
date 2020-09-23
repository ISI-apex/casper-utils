#!/bin/bash

set -e

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export PATH=$(realpath ${SELF_DIR}/../../bin):${PATH}

if [[ "$#" -ne 4 ]]
then
	echo "USAGE: $0 <prefix_path> <cluster> <cpu_family> <gpu>" 1>&2
	exit 1
fi

EPREFIX=$(realpath $1)
CLUSTER=$2
ARCH=$3
GPU=$4

WORK_DIR="${SELF_DIR}"/dat/${ARCH}
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

export LOG_DIR=${WORK_DIR}

exec psbatch "${EPREFIX}" "${CLUSTER}" "${ARCH}" "${GPU}:1" all 2 1 00:30:00 \
	--job-name=test-cfd bash "${SELF_DIR}"/test-cfd.sh ${GPU}
