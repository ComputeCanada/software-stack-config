#add site-specific software (/opt/software/bin) and Slurm to $PATH
#this makes sure that the MPI libraries can find libpmi.so.* to communicate with Slurm.
foreach d ( /opt/software/slurm/bin /opt/software/bin /opt/slurm/bin )
	if ( -d "${d}" ) then
		setenv PATH ${d}:${PATH}
	endif
end
if ( $?RSNT_LD_LIBRARY_PATH && ! $?LD_LIBRARY_PATH ) then
	setenv LD_LIBRARY_PATH ${RSNT_LD_LIBRARY_PATH}
endif
