__Init_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
for d in (/opt/software/slurm/bin /opt/software/bin /opt/slurm/bin) ; do
	if [[ -d "$d" ]]; then
		export PATH=$d:$PATH
	fi
done
for d in (/opt/software/slurm/lib /opt/software/slurm/lib64 /opt/software/lib /opt/software/lib64 /opt/slurm/lib64) ; do
	if [[ -d "$d" ]]; then
		export LD_LIBRARY_PATH=$d${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
	fi
done