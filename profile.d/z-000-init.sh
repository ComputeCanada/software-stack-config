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
# for now, disable the transition warning
if [[ -z "$RSNT_ENABLE_STDENV2020_TRANSITION" ]]; then
	export RSNT_ENABLE_STDENV2020_TRANSITION="no"
fi
umask 0027

