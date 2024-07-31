export MODULESHOME=/cvmfs/soft.computecanada.ca/custom/software/lmod/lmod
export __LMOD_SET_KSH_FPATH=1 # temporary workaround for https://github.com/TACC/Lmod/issues/718
source $MODULESHOME/init/profile
export LMOD_PACKAGE_PATH=/cvmfs/soft.computecanada.ca/config/lmod/
export LMOD_ADMIN_FILE=/cvmfs/soft.computecanada.ca/config/lmod/admin.list
export LMOD_AVAIL_STYLE=grouped:system
export LMOD_AVAIL_EXTENSIONS=no
export LMOD_SHORT_TIME=3600
if [[ -z "$RSNT_ENABLE_LMOD_CACHE" ]]; then
	export RSNT_ENABLE_LMOD_CACHE="yes"
fi
if [[ -z "$__Init_Default_Modules" ]]; then
	export LMOD_RC=$LMOD_PACKAGE_PATH/lmodrc.lua
	NEWMODULERCFILE=$LMOD_PACKAGE_PATH/modulerc
	if [[ ! -z "$CC_CLUSTER" && -f $LMOD_PACKAGE_PATH/modulerc_${CC_CLUSTER} ]]; then
		NEWMODULERCFILE=$LMOD_PACKAGE_PATH/modulerc_${CC_CLUSTER}:$NEWMODULERCFILE
	fi
	export MODULERCFILE=${MODULERCFILE:+:$MODULERCFILE}:$NEWMODULERCFILE
	unset NEWMODULERCFILE
	export MODULEPATH=/cvmfs/soft.computecanada.ca/custom/modules
	__Init_Default_Modules=1; export __Init_Default_Modules;
	if [[ -z "$LMOD_SYSTEM_DEFAULT_MODULES" ]]; then
		export LMOD_SYSTEM_DEFAULT_MODULES="StdEnv mii"
	fi
	if [[ $- == *i* ]]; then
		module --initial_load restore
	else
		module -q --initial_load restore
	fi
else
	module refresh
fi

if [[ -d /opt/software/modulefiles ]]; then
	module -q use --priority 10 /opt/software/modulefiles
fi
if [[ -d $HOME/modulefiles ]]; then
	module -q use --priority 100 $HOME/modulefiles
fi
