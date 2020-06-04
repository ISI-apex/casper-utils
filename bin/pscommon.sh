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
		echo "E5410"
		;;
	westmere)
		echo "X5650"
		;;
	sandybridge) # k20 ; ISI gpuk40c machine
		echo "E5-2665"
		;;
	ivybridge)
		echo "E5-2650v2"
		;;
	haswell) # k40
		echo "E5-2640v3"
		;;
	broadwell) # p100
		echo "E5-2640v4"
		;;
	skylake) # v100
		echo "gold-6130|silver-4116"
		;;
	opteron) # Magny-Cours (no dedicated option); 'barcelona' ('amdfam10' is synonym) results in SIGILL
		echo "AMD6176"
		;;
	any)
		echo ""
		;;
	*)
		echo "ERROR: unknown architecture: ${ARCH}" 1>&2
		exit 2
		;;
	esac
}
