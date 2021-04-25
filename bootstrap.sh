#!/usr/bin/env bash

set -e

run() {
	echo "$@"
	"$@"
}

function bootstrap_git_lfs() {
	local mach="$(uname -m)"
	case "$(uname -m)" in
		ppc64le) arch=ppc64le;;
		x86_64|amd64) arch=amd64;;
		*)
			echo "ERROR: unrecognized machine type from uname -m: ${mach}" 1>&2
			exit 1
			;;
	esac

	if ! type -P tar >/dev/null
	then
		echo "ERROR: tar required but not found" 1>&2
		exit 2
	fi
	if ! type -P curl >/dev/null
	then
		echo "ERROR: curl required but not found" 1>&2
		exit 2
	fi

	local GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download
	local GIT_LFS_VER=2.13.3
	local GIT_LFS_TAR=git-lfs-linux-${arch}-v${GIT_LFS_VER}.tar.gz
	local GIT_LFS_MD5
	case "${arch}" in
		amd64) GIT_LFS_MD5=28eafc12b75c29e0416b2cbb34e20758;;
		ppc64le) GIT_LFS_MD5=a2da02c0931ff101a590383080f04089;;
		*)
			echo "ERROR: checksum not set for arch: ${arch}" 1>&2
			exit 3
			;;
	esac

	run mkdir -p git-lfs
	run pushd git-lfs

	if [[ -f "${GIT_LFS_TAR}" ]]
	then
		if type -P md5sum >/dev/null
		then
			if [[ "$(md5sum ${GIT_LFS_TAR} | cut -d' ' -f1)" != "${GIT_LFS_MD5}" ]]
			then
				rm "${GIT_LFS_TAR}"
			fi
		fi
	fi
	if [[ ! -f "${GIT_LFS_TAR}" ]]
	then
		run curl -LRO "${GIT_LFS_URL}/v${GIT_LFS_VER}/${GIT_LFS_TAR}"
		if [[ "$(md5sum ${GIT_LFS_TAR} | cut -d' ' -f1)" != "${GIT_LFS_MD5}" ]]
		then
			echo "ERROR: md5sum mismatch on the downloaded ${GIT_LFS_TAR}" 1>&2
			exit 4
		fi
	fi
	run tar xf "${GIT_LFS_TAR}"

	PREFIX_DIR=$PWD/prefix
	mkdir -p "${PREFIX_DIR}"
	PREFIX=${PREFIX_DIR} run ./install.sh

	PATH=$PATH:${PREFIX_DIR}/bin

	run git-lfs -v
	popd
	echo "Bootstrapped git-lfs successfully"
}

if type -P git-lfs >/dev/null && git-lfs -v >/dev/null
then
	echo "INFO: git-lfs already present: skipping bootstrap"

	# Not a perfect check, but try to not run install unless necessary
	if ! git config filter.lfs.required >/dev/null
	then
		echo "INFO: git-lfs present but not installed:" \
			"installing temporarily"
		run git lfs install
		# Leave no trace: don't change the user's config
		trap "run git lfs uninstall" EXIT
	fi
else
	bootstrap_git_lfs # upstream script does 'git lfs install'
	# Do not expose this bootstrapped git-lfs outside this script.
	# If git-lfs was not installed, then git operations done after
	# bootstrap will simply ignore LFS.
	trap "run git lfs uninstall" EXIT
fi

run git submodule init
run git submodule update

# Workaround for git-lfs bug that causes pull to fail
# https://github.com/git-lfs/git-lfs/issues/4488
DUMMY_REPO=.git-lfs-dummy
[[ -d "${DUMMY_REPO}" ]] || run git init --bare "${DUMMY_REPO}"
run git config filter.lfs.clean "git --git-dir ${DUMMY_REPO} lfs clean -- %f"

run git lfs pull
run git lfs fsck
