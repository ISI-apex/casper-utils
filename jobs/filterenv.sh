#!/usr/bin/env bash

set -e

rune() {
	echo "$@"
	exec "$@"
}

vars=(
	HOME
	SHELL
	PATH
	TERM
	USER
	XDG_RUNTIME_DIR
	XDG_SESSION_ID
)
while [[ "$#" -gt 0 && "$1" != "--" ]]
do
	vars+=("$1")
	shift
done
shift # --

var_vals=()
for var in ${vars[@]}
do
	var_vals+=("${var}=${!var}")
done

rune env -i ${var_vals[@]} "$@"
