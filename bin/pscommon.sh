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
	local ARCH=$1
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
		FEAT="E5-2640v3"
		;;
	broadwell) # p100
		FEAT="E5-2640v4"
		;;
	skylake) # v100
		FEAT="gold-6130|silver-4116"
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
	if [[ "${ARCH}" == opteron ]]
	then
		echo "${FEAT}"
	else
		echo "${FEAT}&IB"
	fi
}
