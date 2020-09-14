#!/bin/bash

set -e

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ "$#" -ne 4 ]]
then
	echo "USAGE: $0 <prefix_path> <cluster> <cpu_family> <gpu>" 1>&2
	exit 1
fi

"${SELF_DIR}"/test-mpi.job.sh "$1" "$2" "$3"
"${SELF_DIR}"/test-cfd.job.sh "$1" "$2" "$3" "$4"
