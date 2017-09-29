setenv MODULESHOME /cvmfs/soft.computecanada.ca/nix/var/nix/profiles/16.09/lmod/lmod
source /cvmfs/soft.computecanada.ca/nix/var/nix/profiles/16.09/lmod/lmod/init/csh
setenv LMOD_PACKAGE_PATH /cvmfs/soft.computecanada.ca/config/lmod/
setenv LMOD_ADMIN_FILE /cvmfs/soft.computecanada.ca/config/lmod/admin.list
setenv MODULERCFILE $LMOD_PACKAGE_PATH/modulerc
setenv LMOD_AVAIL_STYLE grouped:system
setenv LMOD_RC $LMOD_PACKAGE_PATH/lmodrc.lua
setenv LMOD_SHORT_TIME 3600

if ( ! $?__Init_Default_Modules ) then
	setenv MODULEPATH
	module use /cvmfs/soft.computecanada.ca/custom/modules
	setenv __Init_Default_Modules 1
	setenv LMOD_SYSTEM_DEFAULT_MODULES "StdEnv/2016.4"
	module --initial_load restore
else
	if ( ! $?__Init_LD_LIBRARY_PATH && $?EBROOTNIXPKGS ) then
		# workaround newgrp etc. that reset LD_LIBRARY_PATH
		if ( $?LD_LIBRARY_PATH ) then
			setenv LD_LIBRARY_PATH /cvmfs/soft.computecanada.ca/nix/lib:${LD_LIBRARY_PATH}
		else
			setenv LD_LIBRARY_PATH /cvmfs/soft.computecanada.ca/nix/lib
		endif
	endif
	module refresh
endif
unset __Init_LD_LIBRARY_PATH

if ( -d /opt/software/modulefiles ) then
	module -q use --priority 10 /opt/software/modulefiles
endif
if ( -d $HOME/modulefiles ) then
	module -q use --priority 100 $HOME/modulefiles
endif
