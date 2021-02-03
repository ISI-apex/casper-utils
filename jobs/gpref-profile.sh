#!/bin/bash

set -e
set -x

if [[ ! -e "${SELF_DIR}" ]]
then
	echo "ERROR: caller did not set SELF_DIR to script's directory" 1>&2
	exit 1
fi
CASPER_UTILS=$(realpath ${SELF_DIR}/..)
source ${CASPER_UTILS}/prefix-tools/etc/prefixhelpers

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

step_is_done() {
	test -f "${STATUS_DIR}/$1"
}
step_done() {
	touch "${STATUS_DIR}/$1"
}

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
	prun "env PORTAGE_TMPDIR=${TMPDIR} MAKEOPTS=-j$(nproc) $@"
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
	)
	# TODO: scan 'parent' files and pick up etc subfolders if exist
	if [[ "${PROFILE}" =~ generic ]]
	then
		ETC_FILES+=(generic/etc/portage/package.provided)
	elif [[ "${PROFILE}" =~ usc-hpcc ]]
	then
		ETC_FILES+=(usc-hpcc/etc/portage/package.provided)
	elif [[ "${PROFILE}" =~ usc-discovery ]]
	then
		ETC_FILES+=(usc-discovery/etc/portage/package.provided)
	fi
	ETC_DIRS=(
		casper/etc/portage/sets
		casper/etc/portage/env
	)
	for f in ${ETC_FILES[@]}
	do
		cat "$ROOT"/${REPO_PATH}/profiles/${f} \
			>> "$ROOT"/etc/portage/$(basename ${f})
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

# This has to happen after the profile is selected, so that use flags
# for LLVM+Clang are availabe, but before the profile is emerged, so
# that packages that depend on LLVM+Clang gets rebuilt after LLVM+Clang
# is rebuilt with itself.
if ! step_is_done bootstrap_llvm
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
	portrun "emerge ${LLVM_PKGS[@]}" # bootstrap with gcc
	# switch build compiler to Clang, then re-emerge
	for p in ${LLVM_PKGS[@]}
	do
		run sed -i "s@^#\s*\(${p}\)\s\+${CLANG_ENV}\)\s*\$@\1@" \
			"$ROOT"/etc/portage/package.env
	done
	portrun "emerge ${LLVM_PKGS[@]}" # rebuild with Clang
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
	portrun "emerge -v --deep --complete-graph --update --newuse --newrepo @world ${sets[@]}"
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
