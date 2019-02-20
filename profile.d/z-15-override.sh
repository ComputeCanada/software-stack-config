__Init_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
if [[ "$CC_CLUSTER" == "graham" || "$CC_CLUSTER" == "cedar" || "$CC_CLUSTER" == "beluga" ]];
then
	for d in /opt/software/slurm/bin /opt/software/bin ; do
		if [[ -d "$d" ]]; then
			export PATH=$d:$PATH
		fi
	done
        for d in /opt/software/slurm/lib /opt/software/lib ; do
		if [[ -d "$d" ]]; then
			export LD_LIBRARY_PATH=$d${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
		fi
	done
elif [[ "$CC_CLUSTER" == "niagara" ]]; then
	for d in /opt/slurm/bin ; do
		if [[ -d "$d" ]]; then
			export PATH=$d:$PATH
		fi
	done
        for d in /opt/slurm/lib64; do
		if [[ -d "$d" ]]; then
			export LD_LIBRARY_PATH=$d${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
		fi
	done

fi
