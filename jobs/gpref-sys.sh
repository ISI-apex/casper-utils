#!/bin/bash

set -e
set -x

if [[ ! -e "${SELF_DIR}" ]]
then
	echo "ERROR: caller did not set SELF_DIR to script's directory" 1>&2
	exit 1
fi
source "${SELF_DIR}"/gpref-common.sh

set_tmpdir
TMP_HOME="${TMPDIR}" # name used in this script, to avoid confusion

if [[ ! -e "${DIST_PATH}" ]]
then
	echo "ERROR: DIST_PATH not pointing to source archives dir" 1>&2
	exit 1
fi
DIST_PATH=$(realpath ${DIST_PATH})

if [[ ! -e "${FILES_PATH}" ]]
then
	echo "ERROR: FILES_PATH not pointing to dir with job files" 1>&2
	exit 1
fi

# set env var BARE to non-zero value if you just want a prefix,
# but do not want to build the numerical libraries.

PPATH=$1
if [ -z "${PPATH}" ]
then
	echo "ERROR: prefix name not specified as argument" 1>&2
	exit 1
fi

PNAME=$(basename ${PPATH})
export ROOT=$(realpath ${PPATH})

mkdir -p $ROOT

# Workaround for /etc/profile.d/..mx. setting LD_LIBRARY_PATH: wrap shell
mkdir -p "${TMP_HOME}"/bin
export PATH="${TMP_HOME}/bin:$PATH"
echo '/bin/bash --noprofile "$@"' > "${TMP_HOME}"/bin/bash
chmod +x "${TMP_HOME}"/bin/bash
export SHELL="${TMP_HOME}/bin/bash"

export PORTAGE_TMPDIR="${TMP_HOME}"
export DISTDIR="${DIST_PATH}"

# Note: at least on HPCC Discovery cluster, nproc will return only
# as many cores as have been requred from the resource manager. But,
# if nproc returns raw HW cores (on legacy cluster), it's harmless
# to use them all, since it's not enforced.
export USE_CPU_CORES=$(nproc)
export TODO=noninteractive
export OFFLINE_MODE=$OFFLINE_MODE
export SNAPSHOT_DATE=20200604

# This variable may be set on some hosts that use lmod system, but having
# this variable set breaks the normal GCC shipped with the system.
unset GCC_ROOT

## Workaround for failure to create a symlink at end of stage1
mkdir -p $ROOT/tmp/var/db/repos/

# Keep track of which steps are done, so that job can be rerun
STATUS_DIR=$ROOT/status
mkdir -p ${STATUS_DIR}

step_is_done() {
	test -f ${STATUS_DIR}/$1
}
step_done() {
	touch ${STATUS_DIR}/$1
}

if ! step_is_done bootstrap
then
	"${FILES_PATH}"/bootstrap-prefix.sh
	step_done bootstrap
fi

run() {
	echo "$@"
	"$@"
}

prun() {
	run "$ROOT"/startprefix -c "command $1 </dev/null"
}

if ! step_is_done patch_startprefix
then
	# Temporary patch to allow prun; later patched package re-installed
	sed -i 's:\(env. -i $RETAIN $SHELL\) -l:\1 --rcfile "${EPREFIX}"/.prefixrc -i "$@":' "$ROOT"/startprefix
	sed -i '$ i\RC=$?' "$ROOT"/startprefix
	echo 'exit $RC' >> "$ROOT"/startprefix
	patch -p1 "$ROOT"/startprefix ${FILES_PATH}/startprefix.patch
	sed -i 's/\(Leaving .* exit status\) \$[?]/\1 $RC/' "$ROOT"/startprefix
	step_done patch_startprefix
fi

if ! step_is_done make_conf
then
	# When run in offline mode, bootstrap script disables fetching: re-enable
	sed -i '/^FETCH_COMMAND=/d' "$ROOT/etc/portage/make.conf"

	# Bootstrap script sets some default flags, remove them in favor of profile
	sed -i -e 's/^CFLAGS=.*/CFLAGS="${CFLAGS}"/'  \
		-e 's/^CXXFLAGS=.*/CXXFLAGS="${CXXFLAGS}"/' \
		"$ROOT/etc/portage/make.conf"

	echo 'ACCEPT_KEYWORDS="~amd64 ~amd64-linux"' >> "$ROOT/etc/portage/make.conf"
	step_done make_conf
fi

if ! step_is_done locale
then
	sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' "$ROOT"/etc/locale.gen
	prun "locale-gen"
	echo -e "LANG=en_US.UTF-8\nLC_CTYPE=en_US.UTF-8\n" > "$ROOT"/etc/locale.conf
	step_done locale
fi

if ! step_is_done prefixrc
then
	cp "${FILES_PATH}"/prefixenv "$ROOT/.prefixenv"
	sed "s:@__P_DISTDIR__@:${DISTDIR}:" "${FILES_PATH}"/prefixrc > "$ROOT"/.prefixrc

	# The user/group names don't strictly matter, the UID/GID is taken from
	# the prefix dir anyway, but set them to match the host so that ls output
	# is consistent.
	cat <<-EOF > "$ROOT"/.prefixvars
	P_DISTDIR="${DISTDIR}"
	P_GROUP=$(stat -c '%G' "$ROOT")
	P_USER=$(stat -c '%U' "$ROOT")
	EOF
	step_done prefixrc
fi

if ! step_is_done kernel
then
	# Setup kernel sources
	# What follows is specific to CentOS host
	kver="$(uname -r)"
	## If it weren't for the patch, a symlink would suffice
	##mkdir -p "$ROOT"/usr/src
	##ln -sf /usr/src/kernels/$(uname -r) "$ROOT"/usr/src/linux
	## ... when patch is needed
	mkdir -p "$ROOT"/usr/src/kernels
	rsync -aq  /usr/src/kernels/${kver} "$ROOT"/usr/src/kernels/
	ln -sf kernels/${kver} "$ROOT"/usr/src/linux
	pushd "$ROOT"/usr/src/linux
	patch -p1 < "${FILES_PATH}"/kernel-no-pie.patch
	popd
	step_done kernel
fi
