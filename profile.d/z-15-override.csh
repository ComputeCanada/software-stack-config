if ( $?CC_CLUSTER ) then
    if ( "$CC_CLUSTER" == "graham" || "$CC_CLUSTER" == "cedar" ) then
	foreach d ( /opt/software/slurm/bin /opt/software/bin )
		if ( -d "$d" ) then
			setenv PATH $d:$PATH
		endif
	end
        foreach d ( /opt/software/slurm/lib /opt/software/lib )
		if ( -d "$d" ) then
                        if ( $?LD_LIBRARY_PATH ) then
			        setenv LD_LIBRARY_PATH $d:$LD_LIBRARY_PATH
                        else
                                setenv LD_LIBRARY_PATH $d
                        endif
		endif
	end
    endif
endif
