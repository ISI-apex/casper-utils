#!/bin/bash

set -e
set -x

if [[ ! -e "${SELF_DIR}" ]]
then
	echo "ERROR: caller did not set SELF_DIR to script's directory" 1>&2
	exit 1
fi
source "${SELF_DIR}"/../bin/pscommon.sh

set_tmpdir 16000 # MB of free space
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

if [[ -z "${NPROC}" ]]
then
	# Note: at least on HPCC Discovery cluster, nproc will return only
	# as many cores as have been requested from the resource manager.
	# But, if nproc returns raw HW cores (on legacy cluster), it's
	# harmless to use them all, since it's not enforced.
	NPROC=$(nproc)
fi

# Env vars read by bootstrap-prefix.sh
export USE_CPU_CORES=${JOBS}
export TODO=noninteractive
export OFFLINE_MODE=$OFFLINE_MODE
export SNAPSHOT_DATE=20200604

# This variable may be set on some hosts that use lmod system, but having
# this variable set breaks the normal GCC shipped with the system.
# TODO: there are probably many like these... so maybe just run the
# whole script in a clean environment (env -i)?
unset GCC_ROOT
unset COMPILER_PATH

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
	# This script is incremental itself
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
	# Temporary patch to allow prun; in gpref-profile job the patched
	# version of app-portage/prefix-toolkit reinstalls this script.
	# Note: P1, P2 are not in a .patch because the script has the
	# explicit path to prefix, which would require generating .patch.
	#
	# P1: Load .prefixrc file in interactive and non-inter. mode.
	sed -i 's:\(env. -i $RETAIN\) -l:\1 BASH_ENV="${EPREFIX}/.prefixrc" $SHELL --rcfile "${EPREFIX}"/.prefixrc "$@":' "$ROOT"/startprefix
	# P2: Do propagate the exit code to caller
	sed -i '$ i\RC=$?' "$ROOT"/startprefix
	echo 'exit $RC' >> "$ROOT"/startprefix
	sed -i 's/\(Leaving .* exit status\) \$[?]/\1 $RC/' "$ROOT"/startprefix
	# P3: Read env vars to preserve from .prefixenv file
	patch -p1 "$ROOT"/startprefix ${FILES_PATH}/startprefix.patch
	sed -i 's/$RETAIN/"${RETAIN[@]}"/g' "$ROOT"/startprefix # part of the above .patch
	step_done patch_startprefix
fi

if ! step_is_done make_conf
then
	# When run in offline mode, bootstrap script disables fetching: re-enable
	sed -i '/^FETCH_COMMAND=/d' "$ROOT/etc/portage/make.conf"

	# ... but for live VCS packages (including ones that snapshot by date),
	# the online fetch happens unconditionally, so we have to disable it
	sed -i '/^EVCS_OFFLINE=/d' "$ROOT/etc/portage/make.conf"
	echo 'EVCS_OFFLINE=1' >> "$ROOT/etc/portage/make.conf"

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
	# It's not great to copy since updates to this code in casper-utils
	# won't propagate to prefixes that were already built, but the greater
	# evil is to introduce a dependency from prefix on casper-utils, we
	# want the prefix to be standalone in this sense, with casper-utils
	# having the role of a build tool.
	cp "${SELF_DIR}"/../bin/pscommon.sh "$ROOT/.prefixhelpers"
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

kern_info()
{
	local srcdir=$1
	local rc=0
	if [[ ! -e "$srcdir" ]]
	then
		echo "notice: kernel src not found at: $srcdir" 1>&2
		echo "$rc"
		return
	fi
	if [[ ! -f "$srcdir"/.config ]]
	then
		echo "notice: no .config in kernel src at: $srcdir" 1>&2
		rc=$((rc | 0x2))
	fi
	if [[ ! -f "$srcdir"/Module.symvers ]]
	then
		echo "notice: no Module.symvers in kernel src at: $srcdir" 1>&2
		rc=$((rc | 0x4))
	fi
	# Try to figure out version of kernel sources to see if we need PIE patch
	if [[ -f "$srcdir"/Makefile ]]
	then
		local ver=$(sed -n 's/^VERSION\s*=\s*\(.*\)/\1/p' \
			"$srcdir"/Makefile)
		if [[ -n "$ver" ]]
		then
			if [[ "$ver" -le 3 ]]
			then
				echo "notice: need PIE patch for kern src at: $srcdir" 1>&2
				rc=$((rc | 0x8))
			fi
		else
			echo "notice: can't parse kern version from: $srcdir/Makefile" 1>&2
			rc=$((rc | 0x10))
		fi
	else
			rc=$((rc | 0x10))
	fi
	if [[ "$((rc & 0x10))" -ne 0 ]]
	then
		echo "notice: won't apply PIE patch because can't determine kernel version in: $srcdir" 1>&2
	fi
	# return would be nicer, but triggers set -e
	echo "$rc"
}

if ! step_is_done kernel
then
	mkdir -p "$ROOT"/usr/src

	ksrcpath=/usr/src/linux
	rc=$(kern_info "$ksrcpath")
	if [[ "$rc" -eq 1 ]] # path not found
	then
		ksrcpath=/usr/src/kernels/$(uname -r)
		rc=$(kern_info "$ksrcpath")
		if [[ "$rc" -eq 1 ]] # path not found
		then
			echo "ERROR: kernel src not found at /usr/src/{linux,kernels/*}" 1>&2
			exit 1
		fi
	fi
	if  [[ "$rc" -eq 0 ]]
	then
		# In the best case, a symlink suffices
		ln -sf $ksrcpath "$ROOT"/usr/src/linux
	else # in all other cases, we'll need a copy
		# indirect via a symlink, although not strictly necessary
		kver="$(uname -r)"
		mkdir -p "$ROOT"/usr/src/kernels
		cp -a ${ksrcpath}/ "$ROOT"/usr/src/kernels/${kver}
		ln -sf kernels/${kver} "$ROOT"/usr/src/linux

		if [[ "$((rc & 0x2))" -ne 0 ]] # no .config
		then
			proc_config=/proc/config.gz
			if [[ -e "${proc_config}" ]]
			then
				zcat "${proc_config}" > "$ROOT"/usr/src/linux/.config
			else
				echo "ERROR: .config not found in kern src dir nor /proc" 1>&2
				exit 1
			fi
		fi

		if [[ "$((rc & 0x4))" -ne 0 ]] # no Module.symvers
		then
			mod_symvers=/usr/src/linux-headers-$(uname -r)/Module.symvers
			if [[ -e "${mod_symvers}" ]]
			then
				cp -a "${mod_symvers}" "$ROOT"/usr/src/linux/Module.symvers
			else
				echo "WARNING: Module.symvers not found in kern src dir nor elsewhere" 1>&2
				echo "Will rely on x11-drivers/nvidia-drivers to set IGNORE_MISSING_MODULE_SYMVERS=1" 1>&2
			fi
		fi

		if [[ "$((rc & 0x8))" -ne 0 ]] # need PIE patch
		then
			pushd "$ROOT"/usr/src/linux
			patch -p1 < "${FILES_PATH}"/kernel-no-pie.patch
			popd
		fi

		# NOTE: any error not handled above, is assumed benign
	fi
	step_done kernel
fi
