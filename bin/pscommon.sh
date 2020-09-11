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
		legacy)
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
			if [[ "${CLUSTER}" = legacy ]]
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
