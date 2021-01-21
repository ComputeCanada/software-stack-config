if ( ! $?CC_CLUSTER && -r /etc/environment ) then
	# try to recover from /etc/environment (not used by slurm)
	setenv CC_CLUSTER `grep ^CC_CLUSTER /etc/environment | cut -d= -f2`
endif
if ( ! $?CC_CLUSTER ) then
	setenv CC_CLUSTER "computecanada"
endif
if ( -d "/cvmfs/restricted.computecanada.ca/easybuild" ) then
	setenv CC_RESTRICTED "true"
endif
# for now, disable the transition warning
if ( ! $?RSNT_ENABLE_STDENV2020_TRANSITION ) then
	setenv RSNT_ENABLE_STDENV2020_TRANSITION "no"
endif
umask 0027

