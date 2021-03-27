#!/usr/bin/env bash

set -e

rune() {
	echo "$@"
	exec "$@"
}

vars=(
	HOME="${HOME}"
	SHELL="${SHELL}"
	PATH="${PATH}"
	TERM="${TERM}"
	USER="${USER}"
	XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR}"
	XDG_SESSION_ID="${XDG_SESSION_ID}"
)
while [[ "$#" -gt 0 && "$1" != "--" ]]
do
	vars+=("$1")
	shift
done
shift # --

rune env -i ${vars[@]} "$@"
