if [[ "$CC_CLUSTER" == "graham" || "$CC_CLUSTER" == "cedar" ]]; 
then
	for d in /opt/software/slurm/bin /usr/nfsshare/slurm/bin /opt/puppetlabs/puppet/bin; do
		if [[ -d "$d" ]]; then
			export PATH=$d:$PATH
		fi
	done
fi

