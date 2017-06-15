#if [[ ($UID -ge 3000000 && $UID -le 5999999) || ($UID -ge 10000000 && $UID -le 12999999) || ($UID -ge 15000000 && $UID -le 16999999) || $USER == "ebuser" || $USER == "libuser" || $USER == "nixuser" ]]
if [[ $UID -ge 1001 && $SKIP_CVMFS -ne 1 ]]
then
	for file in /cvmfs/soft.computecanada.ca/config/profile.d/*.sh; do
		if [[ -r "$file" ]]; then
			source $file
		fi
	done
fi
