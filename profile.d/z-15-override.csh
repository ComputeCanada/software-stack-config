#add site-specific software (/opt/software/bin) and Slurm to $PATH
#the RSNT_* workarounds are necessary to survive newgrp (for LD_LIBRARY_PATH) and
# salloc (for SLURM_MPI_TYPE)
foreach d ( /opt/software/slurm/bin /opt/software/bin /opt/slurm/bin )
	if ( -d "${d}" ) then
		setenv PATH ${d}:${PATH}
	endif
end
if ( $?RSNT_LD_LIBRARY_PATH && ! $?LD_LIBRARY_PATH ) then
	setenv LD_LIBRARY_PATH ${RSNT_LD_LIBRARY_PATH}
endif
if ( $?RSNT_SLURM_MPI_TYPE && ! $?SLURM_MPI_TYPE ) then
	setenv SLURM_MPI_TYPE ${RSNT_SLURM_MPI_TYPE}
endif
