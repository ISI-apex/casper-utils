RCFILE=.prefixrc

run() {
	echo "$@"
	"$@"
}

runexec() {
	echo "$@"
	exec "$@"
}

constraint() {
	local CLUSTER=$1
	local ARCH=$2
	node_info "${CLUSTER}" "${ARCH}"
	echo "${FEAT}"
}

node_info() {
	local CLUSTER=$1
	local ARCH=$2

	case "${CLUSTER}" in
		hpcc)
			# Keeping nodes that disappeared, for reference
			local REMOVED=""
			case "$ARCH" in
				harpertown)
					FEAT="E5410"
					REMOVED=1
					;;
				westmere)
					FEAT="X5650"
					REMOVED=1
					;;
				sandybridge) # GPU: k20 ; ISI gpuk40c machine
					FEAT="E5-2665"
					MIN_CORES=16
					;;
				ivybridge)
					FEAT="E5-2650v2"
					REMOVED=1
					;;
				haswell) # GPU: k40
					FEAT="E5-2640v3"
					REMOVED=1
					;;
				broadwell) # GPU: p100
					FEAT="E5-2640v4"
					REMOVED=1
					;;
				skylake) # v100
					FEAT="gold-6130|silver-4116"
					REMOVED=1
					;;
				skylake-gold)
					FEAT="gold-6130"
					REMOVED=1
					;;
				skylake-silver)
					FEAT="silver-4116"
					REMOVED=1
					;;
				opteron) # Magny-Cours (no dedicated option);
					 # 'barcelona' ('amdfam10' is synonym)
					 # results in SIGILL
					FEAT="AMD6176"
					REMOVED=1
					;;
				any)
					FEAT=""
					MIN_CORES=12
					;;
				*)
					echo "ERROR: Arch ${ARCH} not in cluster ${CLUSTER}" 1>&2
					exit 1
					;;
			esac
			if [[ -n "${REMOVED}" ]]
			then
				echo "ERROR: Arch ${ARCH} no longer in cluster ${CLUSTER}" 1>&2
				exit 1
			fi
			# Restrict to Infiniband nodes, because Myrinet nodes
			# hang with /scratch See ITS Ticket RITM0188766; except
			# for Opteron, which are all on Myrinet.  Note that
			# multiple --constraints args are not allowed (later
			# override earlier) and --constraint cannot understand
			# an expression (nested parens with # precedence), it
			# gets converted into a list of features, with an
			# AND/OR/XAND/XOR "modifier" attached to each feature.
			# So, to achieve (f1|f2)&f3, passing 'f1|f2&f3' should
			# work.  See build_feature_list() in
			# src/slurmctld/job_scheduler.c
			#
			# Update: Myrinet (and Opteron) nodes have been removed.
			# Keeping this here just for reference.
			if [[ "${CLUSTER}" = hpcc ]]
			then
				if [[ "${ARCH}" != opteron ]]
				then
					echo "${FEAT}&IB"
				fi
			else
				echo "${FEAT}"
			fi
			;;
		discovery)
			# TODO: label these with what GPUs are hooked up to each
			case "$ARCH" in
			haswell)
				FEAT="xeon-2640v3"
				MIN_CORES=16
				;;
			broadwell)
				FEAT="xeon-2640v4"
				MIN_CORES=20
				;;
			skylake)
				FEAT="xeon-6130|xeon-4116"
				MIN_CORES=24
				;;
			skylake-gold)
				FEAT="xeon-6130"
				MIN_CORES=32
				;;
			skylake-silver)
				FEAT="xeon-4116"
				MIN_CORES=24
				;;
			any)
				FEAT=""
				MIN_CORES=16
				;;
			*)
				echo "ERROR: arch ${ARCH} not in cluster ${CLUSTER}" 1>&2
				exit 1
				;;
			esac
			;;
		*)
			echo "ERROR: invalid cluster: ${CLUSTER}" 1>&2
			exit 1
			;;
	esac

	if [[ -z "${MIN_CORES}" ]] # internal error-catcher
	then
		echo "ERROR: MIN_CORES not set (check case above)" 1>&2
		exit 1
	fi
}

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
			if [ -n "${THE_TMPDIR}" ] && \
				check_space_mb "${THE_TMPDIR}" "${min_space_mb}"
			then
				tmp_root="${THE_TMPDIR}"
			fi
			elif check_space_mb /tmp "${min_space_mb}"
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
			if [ -n "${THE_TMPDIR}" ]
			then
				tmp_root="${THE_TMPDIR}"
			else
				tmp_root=/tmp
			fi
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
