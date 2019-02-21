if ( $?LD_LIBRARY_PATH ) then
    set __init_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
endif

foreach d ( /opt/software/slurm/bin /opt/software/bin /opt/slurm/bin )
	if ( -d "${d}" ) then
		setenv PATH ${d}:${PATH}
	endif
end
foreach d ( /opt/software/slurm/lib /opt/software/slurm/lib64 /opt/software/lib /opt/software/lib64 /opt/slurm/lib64 )
	if ( -d "${d}" ) then
		if ( $?LD_LIBRARY_PATH ) then
			setenv LD_LIBRARY_PATH ${d}:${LD_LIBRARY_PATH}
		else
			setenv LD_LIBRARY_PATH ${d}
		endif
	endif
end