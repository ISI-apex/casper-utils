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

# sets TMPDIR, needed by prun (via .prefixrc)
set_tmpdir "${CLUSTER}" 16000 "$ROOT" # MB of space

echo "$(basename $0): host $(hostname) procs ${NPROC} tmpdir ${TMPDIR}"

step_is_done() {
	test -f "${STATUS_DIR}/$1"
}
step_done() {
	touch "${STATUS_DIR}/$1"
}

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
	prun "eselect profile set ${REPO}:${PROFILE}"
	step_done select_profile
fi

if ! step_is_done select_profile_etc
then
	# Manual parts of selecting the profile:
	#   Setup files that are not supported by profiles (but we do
	#   store them in the profiles directory tree to keep stuff together)

	# Walks the tree in depth-first order, returns list of profile names
	# Usage: profile_tree path_to_profiles_dir_in_ebuild_repo root_profile
	function profile_tree() {
		local dir="$1"
		local prof="$2"
		if [[ -f "${dir}"/"${prof}"/parent ]]
		then
			local line parent_prof
			while read -r line
			do
				parent_prof=${line#../}
				if [[ ! "${parent_prof}" =~ gentoo: ]]
				then
					profile_tree "${dir}" "${parent_prof}"
				fi
			done < "${dir}"/"${prof}"/parent
		fi
		echo "${prof}"
	}
	function is_dir_not_empty() {
		typeset dir="${1:?required directory argument is missing}"
		if [[ ! -d "${dir}" ]]
		then
			return 1
		fi
		set -- ${dir}/*
		if [ "${1}" == "${dir}/*" ]
		then
			return 1
		else
			return 0
		fi
	}
	profiles=($(profile_tree "$ROOT"/${REPO_PATH}/profiles "${PROFILE}"))
	for profile in "${profiles[@]}"
	do
		profile_path=${REPO_PATH}/profiles/${profile}
		# These files are merged
		ETC_FILES=(
			package.env
			package.license
			package.provided
		)
		# All files in these diretories are symlinked;
		# later profiles override earlier profiles
		ETC_DIRS=(
			sets
			env
		)
		for f in ${ETC_FILES[@]}
		do
			ETC_FILE=${profile_path}/etc/portage/${f}
			if [[ -f "$ROOT"/"${ETC_FILE}" ]]
			then
				merged_file="$ROOT"/etc/portage/${f}
				echo -e "\n# BEGIN: ${ETC_FILE}\n" >> "${merged_file}"
				cat "$ROOT"/"${ETC_FILE}" >> "${merged_file}"
				echo -e "\n# END: ${ETC_FILE}\n" >> "${merged_file}"
			fi
		done
		for d in ${ETC_DIRS[@]}
		do
			ETC_DIR=${profile_path}/etc/portage/${d}
			if is_dir_not_empty "$ROOT"/"${ETC_DIR}"
			then
				mkdir -p "$ROOT"/etc/portage/${d}
				(
					cd "$ROOT"/"${ETC_DIR}"
					for f in *
					do
						ln -sf ../../../${ETC_DIR}/${f} \
							"$ROOT"/etc/portage/${d}/${f}
					done
				)
			fi
		done
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
	if prun "eselect modules has python"
	then
		# select latest installed version of python
		prun 'eselect python set python$(equery -q -C l -F '$version' python | sort -Vr | head -1 | cut -d'.' -f1-2)'
	fi
	step_done select_python
fi

if ! step_is_done depclean_post
then
	# Remove old python versions and potentially other unnecessary leftovers
	portrun "emerge --depclean"
	step_done depclean_post
fi

if ! step_is_done vcs_online
then
	# Turn on online mode after the prefix build is done, this is necessary
	# for VCS packages with snapshot versions (see snapshot.eclass)
	# to rebuild the new version after their recipes had been updated.
	sed -i 's/^EVCS_OFFLINE=1/#EVCS_OFFLINE=1/' "$ROOT"/etc/portage/make.conf
	step_done vcs_online
fi

if ! step_is_done git_lfs
then
	# Note: we assume dev-vcs/git-lfs is listed in the profile's packages list
	# installation of git-lfs needs another step
	prun "git --git-dir ${CASPER_UTILS}/.git lfs install --local"
	step_done git_lfs
fi
