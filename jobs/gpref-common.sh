function get_free_space_mb
{
	echo $(($(stat -f --format="%a*%S" "$1") / (1024*1024)))
}

function check_space_mb
{
	local path=$1
	local space_mb=$2
	[[ "$(get_free_space_mb "${path}")" -ge "${min_space_mb}" ]]
}

# Set TMPDIR to a temporary directory to be used as build dir.  Uses directory
# allocated by resource manager (SLURM) if set, otherwise, creates one with
# mktemp, and registers a cleanup hook.
#
# NOTE: This function replaces the EXIT trap handler. Be careful if you
# want to use this function and use EXIT trap handler from your script.
function set_tmpdir
{
	local min_space_mb=$1

	if [[ -z "${THE_TMPDIR}" ]]
	then
		# Try to use the tmp dir alloce to the job by resource manager
		if [[ -n "${SLURM_TMPDIR}" ]]
		then
			THE_TMPDIR="${SLURM_TMPDIR}"
		elif [[ -n "${TMPDIR}" ]]
		then
			THE_TMPDIR="${TMPDIR}"
		fi
	fi

	# /tmp is not good enough, create a dedicated dir within /tmp
	function cleanup_tmp {
		if [[ -n "${THE_TMPDIR}" && -e "${THE_TMPDIR}" ]]
		then
			rm -rf "${THE_TMPDIR}"
		fi
	}
	if [[ -z "${THE_TMPDIR}" || "${THE_TMPDIR}" =~ ^/tmp|/dev/shm$ ]]
	then
		local tmp_root
		if [[ -n "${min_space_mb}" ]]
		then
			if check_space_mb /tmp "${min_space_mb}"
			then
				tmp_root=/tmp
			elif check_space_mb /dev/shm "${min_space_mb}"
			then
				tmp_root=/dev/shm
			else
				echo "ERROR: no temp dir has ${min_space_mb} MB of space" 1>&2
				exit 1
			fi
		else
			tmp_root=/tmp
		fi
		unset TMPDIR # otherwise mktemp ignores -p
		THE_TMPDIR=$(mktemp -p "${tmp_root}" -d -t $(whoami)-gpref-XXX)
		# This cleanup is imprefect: if job is killed by resource
		# manager, the trash will remain. If we get to this case, then
		# we rely on the user to manually clean up. So, ideally, we
		# would not get to this case, i.e. resource manager would
		# allocate a temp dir and we use it above.

		# NOTE: this replaces the handler, not easy to append...
		trap cleanup_tmp EXIT
	fi

	if [[ ! -e "${THE_TMPDIR}" ]]
	then
		echo "ERROR: temp directory '${THE_TMPDIR}' does not exist" 1>&2
		exit 1
	elif ! touch ${THE_TMPDIR}/test_tmp
	then
		echo "ERROR: temp directory '${THE_TMPDIR}' not writable" 1>&2
		exit 1
	fi

	export TMPDIR="${THE_TMPDIR}"
	echo "TMPDIR=${TMPDIR}"
}
