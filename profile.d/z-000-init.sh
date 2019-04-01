if [[ -z "$CC_CLUSTER" && -r /etc/environment ]]; then
	# try to recover from /etc/environment (not used by slurm)
	export CC_CLUSTER=$(grep ^CC_CLUSTER /etc/environment | cut -d= -f2)
fi
if [[ -z "$CC_CLUSTER" ]]; then
	export CC_CLUSTER="computecanada"
fi
