if ( ! $?CC_CLUSTER && -r /etc/environment ) then
	# try to recover from /etc/environment (not used by slurm)
	setenv CC_CLUSTER `grep ^CC_CLUSTER /etc/environment | cut -d= -f2`
endif
if ( ! $?CC_CLUSTER ) then
	setenv CC_CLUSTER "computecanada"
endif
