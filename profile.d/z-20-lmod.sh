export MODULESHOME=/cvmfs/soft.computecanada.ca/nix/var/nix/profiles/16.09/lmod/lmod
source /cvmfs/soft.computecanada.ca/nix/var/nix/profiles/16.09/lmod/lmod/init/profile
export LMOD_PACKAGE_PATH=/cvmfs/soft.computecanada.ca/config/lmod/
export LMOD_ADMIN_FILE=/cvmfs/soft.computecanada.ca/config/lmod/admin.list
export LMOD_AVAIL_STYLE=grouped:system
export LMOD_RC=$LMOD_PACKAGE_PATH/lmodrc.lua
export LMOD_SHORT_TIME=3600

if [[ -z "$__Init_Default_Modules" ]]; then
	NEWMODULERCFILE=$LMOD_PACKAGE_PATH/modulerc
	if [[ ! -z "$CC_CLUSTER" && -f $LMOD_PACKAGE_PATH/modulerc_${CC_CLUSTER} ]]; then
		NEWMODULERCFILE=$LMOD_PACKAGE_PATH/modulerc_${CC_CLUSTER}:$NEWMODULERCFILE
	fi
	export MODULERCFILE=${MODULERCFILE:+:$MODULERCFILE}:$NEWMODULERCFILE
	unset NEWMODULERCFILE
	export MODULEPATH=
	module use /cvmfs/soft.computecanada.ca/custom/modules
	__Init_Default_Modules=1; export __Init_Default_Modules;
	if [[ -z "$LMOD_SYSTEM_DEFAULT_MODULES" ]]; then
		export LMOD_SYSTEM_DEFAULT_MODULES="StdEnv"
	fi
	module --initial_load restore
else
	if [[ -z "$__Init_LD_LIBRARY_PATH" && -a "$EBROOTNIXPKGS" ]]; then
		# workaround newgrp etc. that reset LD_LIBRARY_PATH
		export LD_LIBRARY_PATH=/cvmfs/soft.computecanada.ca/nix/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
	fi
	module refresh
fi
unset __Init_LD_LIBRARY_PATH

if [[ -d /opt/software/modulefiles ]]; then
	module -q use --priority 10 /opt/software/modulefiles
fi
if [[ -d $HOME/modulefiles ]]; then
	module -q use --priority 100 $HOME/modulefiles
fi
