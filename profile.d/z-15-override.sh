__Init_LD_LIBRARY_PATH=$LD_LIBRARY_PATH

#add site-specific software (/opt/software/bin) and Slurm to $PATH
#this makes sure that the MPI libraries can find libpmi.so.* to communicate with Slurm.
for d in (/opt/software/slurm/bin /opt/software/bin /opt/slurm/bin) ; do
	if [[ -d "$d" ]]; then
		export PATH=$d:$PATH
	fi
done
for d in (/opt/software/slurm/lib /opt/software/slurm/lib64 /opt/slurm/lib /opt/slurm/lib64) ; do
	if [[ -f "$d/libslurm.so" ]]; then
		export LD_LIBRARY_PATH=$d${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
	fi
done
