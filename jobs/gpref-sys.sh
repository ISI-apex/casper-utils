#!/bin/bash

JOBS=$(nproc)

set -e
set -x

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ ! -e "${TMP_HOME}" ]]
then
	echo "ERROR: TMP_HOME var not pointing to a temp dir" 1>&2
	exit 1
fi

if [[ ! -e "${DIST_PATH}" ]]
then
	echo "ERROR: DIST_PATH not pointing to source archives dir" 1>&2
	exit 1
fi
DIST_PATH=$(realpath ${DIST_PATH})

# set env var BARE to non-zero value if you just want a prefix,
# but do not want to build the numerical libraries.

PPATH=$1
if [ -z "${PPATH}" ]
then
	echo "ERROR: prefix name not specified as argument" 1>&2
	exit 1
fi

if ! which git 2>/dev/null 2>/dev/null
then
	echo "ERROR: git is required but was not found in PATH" 1>&2
	exit 1
fi

PNAME=$(basename ${PPATH})
export ROOT=$(realpath ${PPATH})

# directory with files that accompanies this job
FILES=${SELF_DIR}/gpref

mkdir -p $ROOT

# Workaround for /etc/profile.d/..mx. setting LD_LIBRARY_PATH: wrap shell
mkdir -p "${TMP_HOME}"/bin
export PATH="${TMP_HOME}/bin:$PATH"
echo '/bin/bash --noprofile "$@"' > "${TMP_HOME}"/bin/bash
chmod +x "${TMP_HOME}"/bin/bash
export SHELL="${TMP_HOME}/bin/bash"

# Clear the prefix dir (useful for re-running the job)
rm -rf "$ROOT"

export PORTAGE_TMPDIR="${TMP_HOME}"
export DISTDIR="${DIST_PATH}"

export USE_CPU_CORES=$JOBS
export TODO=noninteractive
export OFFLINE_MODE=$OFFLINE_MODE
export SNAPSHOT_DATE=20200330
# TODO: have single date for both gentoo-*.tar.bz2 and portage-*.tar.gz2
export SNAPSHOT_PORTAGE_DATE=20200211

## Workaround for failure to create a symlink at end of stage1
mkdir -p $ROOT/tmp/var/db/repos/

"${FILES}"/bootstrap-prefix.sh

run() {
	echo "$@"
	"$@"
}

prun() {
	run "$ROOT"/startprefix -c "command $1 </dev/null"
}

# When run in offline mode, bootstrap script disables fetching: re-enable
sed -i '/^FETCH_COMMAND=/d' "$ROOT/etc/portage/make.conf"

echo 'ACCEPT_KEYWORDS="~amd64 ~amd64-linux"' >> "$ROOT/etc/portage/make.conf"

sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' "$ROOT"/etc/locale.gen
prun "locale-gen"
echo -e "LANG=en_US.UTF-8\nLC_CTYPE=en_US.UTF-8\n" > "$ROOT"/etc/locale.conf

cp "${FILES}"/prefixenv "$ROOT/.prefixenv"
sed "s:@__P_DISTDIR__@:${DISTDIR}:" "${FILES}"/prefixrc > "$ROOT"/.prefixrc

# The user/group names don't strictly matter, the UID/GID is taken from
# the prefix dir anyway, but set them to match the host so that ls output
# is consistent.
cat <<EOF > "$ROOT"/.prefixvars
P_DISTDIR="${DISTDIR}"
P_GROUP=$(stat -c '%G' "$ROOT")
P_USER=$(stat -c '%U' "$ROOT")
EOF

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
patch -p1 < "${FILES}"/kernel-no-pie.patch
popd

# Temporary patch to allow prun; later patched package re-installed
sed -i 's:\(env. -i $RETAIN $SHELL\) -l:\1 --rcfile "${EPREFIX}"/.prefixrc -i "$@":' "$ROOT"/startprefix
sed -i '$ i\RC=$?' "$ROOT"/startprefix
echo 'exit $RC' >> "$ROOT"/startprefix
patch -p1 "$ROOT"/startprefix ${FILES}/startprefix.patch
