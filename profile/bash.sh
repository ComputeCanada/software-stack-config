#if [[ ($UID -ge 3000000 && $UID -le 5999999) || ($UID -ge 10000000 && $UID -le 12999999) || ($UID -ge 15000000 && $UID -le 16999999) || $USER == "ebuser" || $USER == "libuser" || $USER == "nixuser" ]]
if [[ -f $HOME/.skip_cc_cvmfs ]]; then
	SKIP_CC_CVMFS=1
fi
if [[ -f $HOME/.force_cc_cvmfs ]]; then
	FORCE_CC_CVMFS=1
fi
if [[ ($UID -ge 1000 && $SKIP_CC_CVMFS -ne 1) || ($FORCE_CC_CVMFS -eq 1) ]]
then
	for file in /cvmfs/soft.computecanada.ca/config/profile.d/*.sh; do
		if [[ -r "$file" ]]; then
			source $file
		fi
	done
fi
