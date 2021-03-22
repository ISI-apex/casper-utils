#!/bin/bash

set -e
set -x

if [[ ! -e "${SELF_DIR}" ]]
then
	echo "ERROR: caller did not set SELF_DIR to script's directory" 1>&2
	exit 1
fi
CASPER_UTILS=$(realpath ${SELF_DIR}/..)
source ${CASPER_UTILS}/prefix-tools/etc/prefix-tools/prefixhelpers

if [[ ! -e "${OVERLAY_PATH}" ]]
then
	echo "ERROR: OVERLAY_PATH var not pointing to ebuilds repo" 1>&2
	exit 1
fi
OVERLAY_PATH=$(realpath ${OVERLAY_PATH})

PPATH=$1
if [ -z "${PPATH}" ]
then
	echo "ERROR: prefix name not specified as argument" 1>&2
	exit 1
fi
PROFILE=$2

ROOT=$(realpath ${PPATH})

# Keep track of which steps are done, so that job can be rerun
STATUS_DIR=$ROOT/status
mkdir -p ${STATUS_DIR}

CLUSTER="$(profile_to_cluster "${PROFILE}")"
if [[ -z "${CLUSTER}" ]]
then
	echo "ERROR: can't resolve profile name into cluster name" 1>&2
	exit 2
fi

if [[ -z "${NPROC}" ]]
then
	set_nproc "${CLUSTER}"
fi

step_is_done() {
	test -f "${STATUS_DIR}/$1"
}
step_done() {
	touch "${STATUS_DIR}/$1"
}

if [[ "${PROFILE}" =~ olcf-summit ]]
then
	# On Summit, there is a memory usage limit, so don't use tmpfs (/tmp)
	# for building the profile (base system build does fit in tmpfs).
	TMPDIR="$ROOT"/var/tmp
fi

set_tmpdir 16000 # MB of space; sets TMPDIR, needed by prun (via .prefixrc)

run() {
	echo "$@"
	"$@"
}

prun() {
	# prevent emerge alias (if any) from braking non-interactive script
	run "$ROOT"/startprefix -c "command $1 </dev/null"
}
portrun() {
	# TMPDIR set by set_tmpdir above
	prun "env PORTAGE_TMPDIR=${TMPDIR} MAKEOPTS=-j${NPROC} $@"
}

if ! step_is_done emerge_git
then
	portrun "emerge dev-vcs/git"
	step_done emerge_git
fi

REPO=casper
REPO_PATH=var/db/repos/${REPO}

if ! step_is_done clone_casper_ebuilds
then
	prun "git clone ${OVERLAY_PATH} $ROOT/${REPO_PATH}"
	step_done clone_casper_ebuilds
fi

if ! step_is_done add_casper_repo
then
	mkdir -p "$ROOT"/etc/portage/repos.conf
	cat <<-EOF > "$ROOT"/etc/portage/repos.conf/casper.conf
	[casper]
	priority = 51
	location = $ROOT/${REPO_PATH}
	EOF
	step_done add_casper_repo
fi

if ! step_is_done depclean_pre
then
	# Remove old python versions and potentially other unnecessary leftovers
	portrun "emerge --depclean"
	step_done depclean_pre
fi

if ! step_is_done select_profile
then
	portrun "eselect profile set ${REPO}:${PROFILE}"
	step_done select_profile
fi

if ! step_is_done select_profile_etc
then
	# Manual parts of selecting the profile:
	#   Setup files that are not supported by profiles (but we do
	#   store them in the profiles directory tree to keep stuff together)
	# NOTE: only depth 1 is supported, no nested dirs
	ETC_FILES=(
		casper/etc/portage/package.license
		casper/etc/portage/package.env
		${CLUSTER}/etc/portage/package.provided
	)
	if [[ "${CLUSTER}" =~ anl-theta ]]
	then
		ETC_FILES+=(casper-cross/etc/portage/package.env)
	fi
	ETC_DIRS=(
		casper/etc/portage/sets
		casper/etc/portage/env
	)
	for f in ${ETC_FILES[@]}
	do
		ETC_FILE="$ROOT"/${REPO_PATH}/profiles/${f}
		if [[ -f "${ETC_FILE}" ]]
		then
			cat "${ETC_FILE}" >> "$ROOT"/etc/portage/$(basename ${f})
		fi
	done
	for d in ${ETC_DIRS[@]}
	do
		mkdir -p "$ROOT"/etc/portage/$(basename ${d})
		(
			cd "$ROOT"/${REPO_PATH}/profiles/${d}
			for f in *
			do
				ln -sf ../../../${REPO_PATH}/profiles/${d}/${f} \
					"$ROOT"/etc/portage/$(basename ${d})/${f}
			done
		)
	done
	step_done select_profile_etc
fi

# Remove installed but masked packages. Disabled, because not necessary --
# emerging the profile will take care of it, provided constraints in the
# profile are correct.
#
#if ! step_is_done install_gentoolkit
#then
#	prun "emerge app-portage/gentoolkit"
#	step_done install_gentoolkit
#fi
#
#if ! step_is_done remove_masked
#then
#	pkgs=$(prun "equery -C l -F '\$mask \$cp' '*/*'" | grep ^M | cut -d' ' -f3)
#	prun "emerge -v --depclean --deselect ${pkgs}"
#	step_done remove_masked
#fi

# This has to happen after the profile is selected, so that use flags
# for LLVM+Clang are availabe, but before the profile is emerged, so
# that packages that depend on LLVM+Clang gets rebuilt after LLVM+Clang
# is rebuilt with itself.
if ! step_is_done bootstrap_llvm
then
	# Bootstrap LLVM+Clang with GCC first, then rebuild it with
	# itself. Having an LLVM built with Clang is necessary because
	# MLIR apps build only with Clang (note: if LLVM is and the app
	# is built with GCC, then there are fewer errors, but still not
	# successful).  Even if it worked with GCC, it's best to build
	# all the stuff in LLVM-universe with Clang and eliminate GCC
	# from the picture, only using GCC to bootstrap Clang.  Also
	# rebuilding Clang & Co. (besides LLVM) is optional, but
	# consistent.
	LLVM_PKGS=(
		sys-devel/llvm
		sys-devel/llvm-common
		sys-libs/libomp
		sys-libs/compiler-rt
		sys-libs/compiler-rt-sanitizers
		sys-devel/clang
		sys-devel/clang-common
		sys-devel/clang-runtime
	)
	SAVE_NPROC=${NPROC}
	if [[ "${PROFILE}" =~ olcf-summit ]]
	then
		# The 16GB per-user limit on Summit is enough for -j16 for
		# the whole base system but not enough for LLVM....
		NPROC=8
	fi
	# There's a quoting issue with portrun, so just flatten the list
	LLVM_PKGS_L="${LLVM_PKGS[@]}"
	portrun "emerge ${LLVM_PKGS_L}" # bootstrap with gcc
	# switch build compiler to Clang, then re-emerge
	for p in ${LLVM_PKGS[@]}
	do
		run sed -i "s@^#\s*\(${p}\s\+clang\)\s*\$@\1@" \
			"$ROOT"/etc/portage/package.env
	done
	portrun "emerge ${LLVM_PKGS_L}" # rebuild with Clang
	NPROC=${SAVE_NPROC}
	step_done bootstrap_llvm
fi

if ! step_is_done emerge_profile
then
	sets=()
	if [[ -z "$BARE" ]]
	then
		sets+=("@casper-libs")
	fi
	# Apply use flags, overrides from the newly added repo, install sets
	portrun "emerge -v --deep --complete-graph --update --newuse --newrepo --keep-going @world ${sets[@]}"
	step_done emerge_profile
fi

if ! step_is_done select_python
then
	portrun "eselect python set python3.8"
	step_done select_python
fi

if ! step_is_done depclean_post
then
	# Remove old python versions and potentially other unnecessary leftovers
	portrun "emerge --depclean"
	step_done depclean_post
fi
