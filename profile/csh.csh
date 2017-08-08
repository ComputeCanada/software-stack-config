#if [[ ($UID -ge 3000000 && $UID -le 5999999) || ($UID -ge 10000000 && $UID -le 12999999) || ($UID -ge 15000000 && $UID -le 16999999) || $USER == "ebuser" || $USER == "libuser" || $USER == "nixuser" ]]
set force_cc_cvmfs = 0
if ( $?FORCE_CC_CVMFS ) then
    set force_cc_cvmfs = $FORCE_CC_CVMFS
endif
set skip_cvmfs = 0
if ( $?SKIP_CVMFS ) then
    set skip_cvmfs = $SKIP_CVMFS
endif
if ( ($uid >= 1000 && $skip_cvmfs != 1) || ($force_cc_cvmfs == 1) ) then
	foreach file ( /cvmfs/soft.computecanada.ca/config/profile.d/*.csh )
		if ( -r "$file" ) then
			source $file
		endif
	end
endif
unset force_cc_cvmfs
unset skip_cvmfs
