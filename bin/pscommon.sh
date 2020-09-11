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
			MIN_CORES=12 # TODO: might be underestimated
			;;
		discovery) ;;
		*)
			echo "ERROR: invalid CLUSTER: ${CLUSTER}" 1>&2
			exit 1
			;;
	esac

	case "$ARCH" in
	harpertown)
		FEAT="E5410"
		;;
	westmere)
		FEAT="X5650"
		;;
	sandybridge) # k20 ; ISI gpuk40c machine
		FEAT="E5-2665"
		;;
	ivybridge)
		FEAT="E5-2650v2"
		;;
	haswell) # k40
		case "${CLUSTER}" in
			legacy) FEAT="E5-2640v3";;
			discovery)
				FEAT="xeon-2640v3"
				MIN_CORES=16
				;;
		esac
		;;
	broadwell) # p100
		case "${CLUSTER}" in
			legacy) FEAT="E5-2640v4";;
			discovery)
				FEAT="xeon-2640v4"
				MIN_CORES=20
				;;
		esac
		;;
	skylake) # v100
		case "${CLUSTER}" in
			legacy) FEAT="gold-6130|silver-4116";;
			discovery)
				FEAT="xeon-6130|xeon-4116"
				MIN_CORES=24
				;;
		esac
		;;
	skylake-gold)
		case "${CLUSTER}" in
			legacy)
				FEAT="gold-6130"
				;;
			discovery)
				FEAT="xeon-6130"
				MIN_CORES=32
				;;
		esac
		;;
	skylake-silver)
		case "${CLUSTER}" in
			legacy)
				FEAT="silver-4116"
				;;
			discovery)
				FEAT="xeon-4116"
				MIN_CORES=24
				;;
		esac
		;;
	opteron) # Magny-Cours (no dedicated option); 'barcelona' ('amdfam10' is synonym) results in SIGILL
		FEAT="AMD6176"
		;;
	any)
		FEAT=""
		;;
	*)
		echo "ERROR: unknown architecture: ${ARCH}" 1>&2
		exit 2
		;;
	esac
	# Restrict to Infiniband nodes, because Myrinet nodes hang with /scratch
	# See ITS Ticket RITM0188766; except for Opteron, which are all on Myrinet.
	# Note that multiple --constraints args are not allowed (later override
	# earlier) and --constraint cannot understand an expression (nested
	# parens with # precedence), it gets converted into a list of features,
	# with an AND/OR/XAND/XOR "modifier" attached to each feature. So, to
	# achieve (f1|f2)&f3, passing 'f1|f2&f3' should work.
	# See build_feature_list() in src/slurmctld/job_scheduler.c
	if [[ "${CLUSTER}" = legacy ]]
	then
		if [[ "${ARCH}" != opteron ]]
		then
			echo "${FEAT}&IB"
		fi
	else
		echo "${FEAT}"
	fi
}
