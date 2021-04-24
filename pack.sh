#!/usr/bin/env bash
# An helper to store VCS repos in distfiles/ in git-lfs (Large File Storage).
# We could but don't want to add thousands of tiny files as LFS objects, so
# these pack.sh/unpack.sh scripts pack those repos into tarballs.

function is_dir_empty() {
	typeset dir="${1:?required directory argument is missing}"
	if [[ ! -d "${dir}" ]]
	then
		return 0
	fi
	set -- ${dir}/*
	if [ "${1}" == "${dir}/*" ]
	then
		return 0
	else
		return 1
	fi
}

run() {
	echo "$@"
	"$@"
}

DIST_DIR=distfiles
VCS_DIR=git3-src

if is_dir_empty "${DIST_DIR}"
then
	echo "ERROR: distdir/ is empty: did you fetch git LFS objects?" 1>&2
	exit 1
fi

if is_dir_empty "${DIST_DIR}/${VCS_DIR}"
then
	# nothing to pack
	exit 0
fi

if ! type -P tar >/dev/null
then
	echo "ERROR: tar is required but not found" 1>&2
	exit 2
fi

for repo_path in "${DIST_DIR}/${VCS_DIR}"/*
do
	repo=$(basename ${repo_path})
	run tar -C "${DIST_DIR}/${VCS_DIR}" -c -f "${DIST_DIR}/${VCS_DIR}/${repo}.tar" "${repo}"
done
