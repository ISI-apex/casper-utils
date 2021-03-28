#!/bin/bash

set -e
set -x

if [[ ! -e "${SELF_DIR}" ]]
then
	echo "ERROR: caller did not set SELF_DIR to script's directory" 1>&2
	exit 1
fi
CASPER_UTILS=$(realpath ${SELF_DIR}/..)
source ${CASPER_UTILS}/prefix-tools/sh/prefixhelpers

PTOOLS_DIR="${SELF_DIR}"/../prefix-tools

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
	echo "ERROR: prefix name not specified as first argument" 1>&2
	exit 1
fi

PROFILE=$2
if [ -z "${PROFILE}" ]
then
	echo "ERROR: profile name not specified as second argument" 1>&2
	exit 1
fi

CLUSTER="$(profile_to_cluster "${PROFILE}")"
if [[ -z "${CLUSTER}" ]]
then
	echo "ERROR: can't resolve profile name into cluster name" 1>&2
	exit 2
fi

PNAME=$(basename ${PPATH})
export ROOT=$(realpath ${PPATH})

if [[ -z "${NPROC}" ]]
then
	set_nproc "${CLUSTER}"
fi

set_tmpdir "${CLUSTER}" 16000 "$ROOT" # MB of free space
TMP_HOME="${TMPDIR}" # name used in this script, to avoid confusion

echo "$(basename $0): host $(hostname) procs ${NPROC} tmpdir ${TMPDIR}"

mkdir -p $ROOT

# Workaround for /etc/profile.d/..mx. setting LD_LIBRARY_PATH: wrap shell
# Can't use TMP_HOME because startprefix detects wrapper as prefix shell
# when the path starts with ROOT.
SHELL_WRAP_TMP=$(dirname "${ROOT}")/.tmp.$(basename "${ROOT}")
SHELL_WRAP="${SHELL_WRAP_TMP}"/bin/bash
mkdir -p "$(dirname "${SHELL_WRAP}")"
export PATH="$(dirname "${SHELL_WRAP}"):$PATH"
echo "$SHELL" '--noprofile "$@"' > "${SHELL_WRAP}"
chmod +x "${SHELL_WRAP}"
export SHELL="${SHELL_WRAP}"

# Note: if you edit this path, also edit in startprefix.patch and
# in app-portage/prefix-toolkit ebuild.
ETC_PTOOLS="etc/prefix-tools"

export PORTAGE_TMPDIR="${TMP_HOME}"
export DISTDIR="${DIST_PATH}"

# Env vars read by bootstrap-prefix.sh
export USE_CPU_CORES=${NPROC}
export TODO=noninteractive
export OFFLINE_MODE=$OFFLINE_MODE
export SNAPSHOT_DATE=20210119

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

if ! step_is_done prefixrc
then
	# NOTE: actual prefixrc installed by app-portage/prefix-tools

	cat > "$ROOT/.prefixrc" <<- 'EOF'
	# This file is sourced after $EPREFIX/etc/prefix-tools/prefixrc
	# into every shell (including in non-interactive mode). Add
	# your favoriete aliases and shell prompt config here.
	#
	# The default prompt in Gentoo shows full path, override to shorten
	PS1="\[\033[01;32m\]\u@\h\[\033[01;34m\] \W \$\[\033[00m\] "

	# It is possible to load your favorite ~/.bashrc with all your
	# favorite aliases and settings, but you have be very careful:
	# the ~/.bashrc must not source any config files from the host,
	# however, by default it does!  And, to use your host system, you
	# need that default. One way to go is to split your ~/.bashrc
	# into ~/.bashrc.generic and have ~/.bashrc source
	# ~/.bashrc.generic), then you can uncomment the following:
	#source $HOME/.bashrc.generic
	EOF

	cat > "$ROOT/.prefixenv" <<- 'EOF'
	# To retain env variables when entering prefix via startprefix
	# script, add patterns to match against variable names in
	# Bash regexp format one per line, to this file, e.g.
	# ^MY_ENV_VAR$
	# ^MY_ENV_FAMILY_.*
	EOF

	step_done prefixrc
fi

if ! step_is_done patch_startprefix
then
	# Temporary patch to allow prun; in gpref-profile job the patched
	# version of app-portage/prefix-toolkit reinstalls this script.
	# Note: P1, P2 are not in a .patch because the script has the
	# explicit path to prefix, which would require generating .patch.
	#
	# P1: Load /etc/profile in interactive and non-inter. mode.
	sed -i -e 's:\(env. -i \$RETAIN\) \$SHELL -l:\1 BASH_ENV="${EPREFIX}/etc/profile" $SHELL --rcfile "${EPREFIX}"/etc/profile "$@":' \
		"$ROOT"/startprefix
	# P2: Do propagate the exit code to caller
	sed -i '$ i\RC=$?' "$ROOT"/startprefix
	echo 'exit $RC' >> "$ROOT"/startprefix
	sed -i 's/\(Leaving .* exit status\) \$[?]/\1 $RC/' "$ROOT"/startprefix
	# P3: Read env vars to preserve from .prefixenv file
	${ROOT}/usr/bin/patch -b -p1 "$ROOT"/startprefix ${FILES_PATH}/startprefix.patch
	sed -i 's/$RETAIN/"${RETAIN[@]}"/g' "$ROOT"/startprefix # part of the above .patch
	step_done patch_startprefix
fi

if ! step_is_done make_conf
then
	# When run in offline mode, bootstrap script disables fetching: re-enable
	sed -i '/^FETCHCOMMAND=/d' "$ROOT/etc/portage/make.conf"

	# ... but for live VCS packages (including ones that snapshot by date),
	# the online fetch happens unconditionally, so we have to disable it
	# in offline mode
	sed -i '/^EVCS_OFFLINE=/d' "$ROOT/etc/portage/make.conf"
	if [[ -n "${OFFLINE_MODE}" ]]
	then
		echo 'EVCS_OFFLINE=1' >> "$ROOT/etc/portage/make.conf"
	fi

	# Bootstrap script sets some default flags, remove them in favor of profile
	sed -i -e 's/^CFLAGS=.*/CFLAGS="${CFLAGS}"/'  \
		-e 's/^CXXFLAGS=.*/CXXFLAGS="${CXXFLAGS}"/' \
		"$ROOT/etc/portage/make.conf"

	# hack.. but else to get arch from /etc/portage/make.profile symlink?
	if [[ "${PROFILE}" =~ olcf-summit ]]
	then
		AKW="~ppc64 ~ppc64-linux"
	else
		AKW="~amd64 ~amd64-linux"
	fi
	echo "ACCEPT_KEYWORDS=\"${AKW}\"" >> "$ROOT/etc/portage/make.conf"
	step_done make_conf
fi

if ! step_is_done locale
then
	sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' "$ROOT"/etc/locale.gen
	prun "locale-gen"
	echo -e "LANG=en_US.UTF-8\nLC_CTYPE=en_US.UTF-8\n" > "$ROOT"/etc/locale.conf
	step_done locale
fi

if ! step_is_done passwd
then
	# Take user/group UID/GID and names from owner of prefix directory. The
	# names don't strictly matter, the UID/GID do, but set the names to
	# match the host so that ls output is consistent.
	P_GROUP=$(stat -c '%G' "$ROOT")
	P_USER=$(stat -c '%U' "$ROOT")
	P_UID=$(stat -c '%u' "${ROOT}")
	P_GID=$(stat -c '%g' "${ROOT}")

	sed -i "s@^portage:\([^:]*\):[0-9]\+:portage@${P_GROUP}:\1:${P_GID}:${P_USER}@" \
		"${ROOT}"/etc/group
	sed -i "s@^portage:\([^:]*\):[0-9]\+:[0-9]\+:[^:]*:[^:]*:@${P_USER}:x:${P_UID}:${P_GID}:Prefix User:${HOME}:@" \
		"${ROOT}"/etc/passwd
	step_done passwd
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
			${ROOT}/usr/bin/patch -b -p1 < "${FILES_PATH}"/kernel-no-pie.patch
			popd
		fi

		# NOTE: any error not handled above, is assumed benign
	fi
	step_done kernel
fi

# Setup host-based authentication by copying config from host
# NOTE: this may differ among clusters, so far developed on Summit.
if ! step_is_done ssh
then
	ssh_dir=etc/ssh
	ssh_config="$ROOT/${ssh_dir}/ssh_config"

	declare -A ssh_options
	ssh_options["EnableSSHKeySign"]="yes"
	ssh_options["HostbasedAuthentication"]="yes"

	for opt in ${!ssh_options[@]}
	do
		val="${ssh_options[${opt}]}"
		if grep -q "^\s*${opt}\s\+" "${ssh_config}"
		then
			sed -i "s/^\s*${opt}\s\+.*/${opt} ${val}/" \
				"${ssh_config}"
		else
			echo "${opt} ${val}" >> "${ssh_config}"
		fi
	done

	for key_file in /${ssh_dir}/ssh_host_*_key.pub
	do
		ln -s ${key_file} $ROOT/${key_file}
	done

	# ssh-keysign is a setuid root executable, so point to host's
	ln -sf /usr/libexec/openssh/ssh-keysign $ROOT/usr/lib64/misc/ssh-keysign
	step_done ssh
fi
