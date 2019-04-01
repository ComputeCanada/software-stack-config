#add site-specific software (/opt/software/bin) and Slurm to $PATH
#the RSNT_* workarounds are necessary to survive newgrp (for LD_LIBRARY_PATH) and
# salloc (for SLURM_MPI_TYPE)
for d in /opt/software/slurm/bin /opt/software/bin /opt/slurm/bin ; do
	if [[ -d "$d" ]]; then
		export PATH=$d:$PATH
	fi
done

# working around an issue with seff using /opt/software/slurm/lib
if [[ -z "$RSNT_LD_LIBRARY_PATH" && ! -f "/opt/software/slurm/lib/libslurm.so" && -f "/opt/software/slurm/lib64/libslurm.so" ]]; then
        export RSNT_LD_LIBRARY_PATH=/opt/software/slurm/lib64
fi

if [[ -n "$RSNT_LD_LIBRARY_PATH" && -z "$LD_LIBRARY_PATH" ]]; then
	export LD_LIBRARY_PATH=$RSNT_LD_LIBRARY_PATH
fi
if [[ -n "$RSNT_SLURM_MPI_TYPE" && -z "$SLURM_MPI_TYPE" ]]; then
        export SLURM_MPI_TYPE=$RSNT_SLURM_MPI_TYPE
fi
