if [[ -z "$CC_CLUSTER" ]]; then
	if [[ -d /opt/puppetlabs/puppet/bin && -d /etc/facter/ ]]; then
		export CC_CLUSTER=$(PATH=/opt/puppetlabs/puppet/bin facter --custom-dir /etc/facter/facts.d/ cc_cluster)
	else
	        export CC_CLUSTER="computecanada"
	fi
fi
