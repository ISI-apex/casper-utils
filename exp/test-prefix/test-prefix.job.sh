#!/bin/bash

set -e

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export PATH=$(realpath ${SELF_DIR}/../../bin):${PATH}

if [[ "$#" -ne 3 ]]
then
	echo "USAGE: $0 <prefix_path> <cpu_family> <gpu>" 1>&2
	exit 1
fi

EPREFIX=$1
ARCH=$2
GPU=$3

WORK_DIR="${SELF_DIR}"/dat/${ARCH}
mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

export LOG_DIR=${WORK_DIR}
exec psbatch "${EPREFIX}" "${ARCH}" "${GPU}:1" 12G 1 2 00:30:00 --job-name=test-prefix bash "${SELF_DIR}"/test-prefix.sh
