#!/usr/bin/env bash

set -e

run() {
	echo "$@"
	"$@"
}

CLUSTER=$1

if [[ -z "${CLUSTER}" ]]
then
	CLUSTER=generic
fi

case "${CLUSTER}" in
	olcf-summit) ARCH=ppc64le;;
	anl-theta|isi-gpuk40|generic) ARCH=amd64;;
	*)
		echo "ERROR: unkown platform" 1>&2
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

GIT_LFS_URL=https://github.com/git-lfs/git-lfs/releases/download
GIT_LFS_VER=2.13.3
GIT_LFS_TAR=git-lfs-linux-${ARCH}-v${GIT_LFS_VER}.tar.gz
GIT_LFS_MD5=28eafc12b75c29e0416b2cbb34e20758

run mkdir -p git-lfs
run cd git-lfs

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
fi
run tar xf "${GIT_LFS_TAR}"

PREFIX_DIR=$PWD/prefix
mkdir -p "${PREFIX_DIR}"
PREFIX=${PREFIX_DIR} run ./install.sh

PATH=$PATH:${PREFIX_DIR}/bin
run git-lfs -v

echo "Bootstrapped git-lfs. Set your PATH to"
echo "    PATH=\$PATH:${PREFIX_DIR}/bin"
