if [[ -z "$CC_CLUSTER" && -r /etc/environment ]]; then
	# try to recover from /etc/environment (not used by slurm)
	export CC_CLUSTER=$(grep ^CC_CLUSTER /etc/environment | cut -d= -f2)
fi
if [[ -z "$CC_CLUSTER" ]]; then
	export CC_CLUSTER="computecanada"
fi
if [[ -d "/cvmfs/restricted.computecanada.ca/easybuild" ]]; then
	export CC_RESTRICTED="true"
fi
if [[ -z "$RSNT_HAS_H100" ]]; then
	H100_CLUSTERS="rorqual|nibi|fir|trillium|tamia|killarney|vulcan"
	if [[ $CC_CLUSTER =~ $H100_CLUSTERS ]]; then
		export RSNT_HAS_H100="true"
	else
		export RSNT_HAS_H100="false"
	fi
fi
umask 0027

