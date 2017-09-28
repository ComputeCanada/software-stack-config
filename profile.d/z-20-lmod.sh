export MODULESHOME=/cvmfs/soft.computecanada.ca/nix/var/nix/profiles/16.09/lmod/lmod
source /cvmfs/soft.computecanada.ca/nix/var/nix/profiles/16.09/lmod/lmod/init/profile
export LMOD_PACKAGE_PATH=/cvmfs/soft.computecanada.ca/config/lmod/
export LMOD_ADMIN_FILE=/cvmfs/soft.computecanada.ca/config/lmod/admin.list
export MODULERCFILE=$LMOD_PACKAGE_PATH/modulerc
export LMOD_AVAIL_STYLE=grouped:system
export LMOD_RC=$LMOD_PACKAGE_PATH/lmodrc.lua
export LMOD_SHORT_TIME=3600

if [[ -z "$__Init_Default_Modules" || -z "$__Init_LD_LIBRARY_PATH" ]]; then
	export MODULEPATH=
	module use /cvmfs/soft.computecanada.ca/custom/modules
	__Init_Default_Modules=1; export __Init_Default_Modules;
	export LMOD_SYSTEM_DEFAULT_MODULES="StdEnv/2016.4"
	module --initial_load restore
else
	module refresh
fi
unset __Init_LD_LIBRARY_PATH

if [[ -d /opt/software/modulefiles ]]; then
	module -q use --priority 10 /opt/software/modulefiles
fi
if [[ -d $HOME/modulefiles ]]; then
	module -q use --priority 100 $HOME/modulefiles
fi
