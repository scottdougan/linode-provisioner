#!/bin/bash
#Author: Scott Dougan
#Date: September 22, 2015
#Version: 1.1
#Script to automatically create a linode and provision it.

# Default domain name if one is not specified
DEFAULT_DOMAIN_NAME="example.com"

# Catch TERM singal to kill the parent script
trap "exit 1" TERM
export TOP_PID=$$

# Utility functions for Linode CLI
source linode_utility_functions.sh

# Setup FQDN and hostname
HOSTNAME="$1"
DOMAIN="$2"

# Location of provisioning script
PROVISION_SCRIPT="./provision/provision.sh"

function add_to_ssh_config_file {
	echo "Host	$1" >> "$HOSTNAME"_ssh_config_template
	echo "HOSTNAME	$2" >> "$HOSTNAME"_ssh_config_template
	echo "IdentityFile	~/.ssh/outergo_rsa" >> "$HOSTNAME"_ssh_config_template
	echo "User		$(whoami)" >> "$HOSTNAME"_ssh_config_template
}

rm -f ./provision/FQDN *_ssh_config_template
if [ -z "$HOSTNAME" ]; then
	HOSTNAME="New_$(date +%Y-%m-%d_%H-%M-%S)"
else
	# If hostname is set without a domain use the default
	if [ -z "$DOMAIN" ]; then
		DOMAIN="$DEFAULT_DOMAIN_NAME"
	fi
	echo "$HOSTNAME.$DOMAIN" >> ./provision/FQDN
fi

echo -n "-> Creating Linode $HOSTNAME"
# Puts the linode in group if a domain has been set
if [ -n "$DOMAIN" ]; then
	RESPONSE=$(linode -a create -l "$HOSTNAME" -g "$(echo $DOMAIN | rev| cut -d. -f2 | rev)" -P 'Randompw11!' 2>&1)
else
	RESPONSE=$(linode -a create -l "$HOSTNAME" -P 'Randompw11!' 2>&1)
fi

LINODE_CLI=$(echo $RESPONSE | grep -o -E "linode: command not found")
if [ -n "$LINODE_CLI" ]; then
	echo -e "\nFAILED: Linode Command Line Interface is not installed" 1>&2
	exit
fi
linode_ip $HOSTNAME
SUCCESS=$(echo $RESPONSE | grep -o -E "Completed.")
if [ -z "$SUCCESS" ]; then
	echo -e "\nFAILED: $RESPONSE" 1>&2
	echo  "Try Running \"linode configure\"" 1>&2
	exit
fi

wait_for_status_change $HOSTNAME "being created"
echo -n "-> Booting"
wait_for_status_change $HOSTNAME "brand new"
echo "-> Running!"

echo -n "-> Waiting for ssh to start"
IP=$(linode_ip $HOSTNAME)
wait_for_ssh  $IP

echo "-> Running provisioner: shell"
scp -o StrictHostKeyChecking=no -r provision root@"$IP":/tmp/
ssh root@"$IP" '/tmp/provision/provision.sh'

if [ -n "$1" ]; then
	echo "-> Created a template ssh config file for server: $HOSTNAME"
	add_to_ssh_config_file $HOSTNAME "$HOSTNAME $DOMAIN"
	echo "" >> "$HOSTNAME"_ssh_config_template
	add_to_ssh_config_file $HOSTNAME "direct"
fi
echo "-> Assigned IP: $IP"
rm -f ./provision/FQDN