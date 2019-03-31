#add site-specific software (/opt/software/bin) and Slurm to $PATH
#this makes sure that the MPI libraries can find libpmi.so.* to communicate with Slurm.
for d in /opt/software/slurm/bin /opt/software/bin /opt/slurm/bin ; do
	if [[ -d "$d" ]]; then
		export PATH=$d:$PATH
	fi
done
if [[ -n "$RSNT_LD_LIBRARY_PATH" && -z "$LD_LIBRARY_PATH" ]]; then
	export LD_LIBRARY_PATH=$RSNT_LD_LIBRARY_PATH
fi
