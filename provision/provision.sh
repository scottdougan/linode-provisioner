#!/bin/bash
#Author: Scott Dougan
#Date: June 10, 2015
#Version: 1.0
#Provision a remote system with updates, users, ssh keys and firewall rules.

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

function system_update {
    apt-get update
    apt-get -y upgrade
    echo ""
}

# Returns the primary IP assigned to eth0
function system_primary_ip {
    echo $(ifconfig eth0 | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')
}

function add_user {
    # Creates a user with a public ssh key with sudo access
    local USERNAME="$1"
    if [ ! -n "$USERNAME" ]; then
        echo "No new username argument specified to the function add_user"
        return 1
    fi

    if [ ! -f "$DIR/public_keys/$USERNAME.pub" ]; then
        echo "User: $USERNAME does not have a public key file and will not be created"
        return 1
    fi
    local USERPUBKEY=$(cat "$DIR/public_keys/$USERNAME.pub")

# This part can be improved so that the users password expires.
    adduser $USERNAME --disabled-password --gecos ""
    echo "$USERNAME:changeme" | chpasswd
    usermod -aG sudo $USERNAME
    touch /home/$USERNAME/Change_Password

    mkdir -p /home/$USERNAME/.ssh
    echo "$USERPUBKEY" >> /home/$USERNAME/.ssh/authorized_keys
    chmod 600 /home/$USERNAME/.ssh/authorized_keys
    chmod 700 /home/$USERNAME/.ssh
    chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
    echo ""
}

# Set system timezone
function system_set_timezone {
    local TIMEZONE="$1"
    if [ ! -n "$TIMEZONE" ]; then
        echo "Timezone undefined"
        return 1
    fi

    echo "$TIMEZONE" > /etc/timezone  
    dpkg-reconfigure -f noninteractive tzdata
}

function system_set_hostname {
    local HOSTNAME="$1"
    if [ ! -n "$HOSTNAME" ]; then
        echo "Hostname undefined"
        return 1
    fi
    
    echo "$HOSTNAME" > /etc/hostname
    hostname -F /etc/hostname
}

function system_add_host_entry {
    local IP="$1"
    local FQDN="$2"
    local HOSTNAME="$3"
    if [ -z "$IP" -o -z "$FQDN" -o -z "$HOSTNAME" ]; then
        echo "IP address and/or FQDN and/or hostname undefined"
        return 1
    fi
    
    echo $IP   $FQDN    $HOSTNAME >> /etc/hosts
}

function edit_sshd_config {
    # Disables root SSH access
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    # Disables password authentication
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    service ssh restart 
}

system_update

# Set hostname and FQDN if available
if [ -f "$DIR/FQDN" ]; then
    FQDN=$(cat "$DIR/FQDN")
    HOSTNAME=$(echo $FQDN |  cut -d. -f1 )
    echo "Setting hostname: $HOSTNAME"
    system_set_hostname $HOSTNAME
    echo "Adding $FQDN entry into hosts file"
    system_add_host_entry $(system_primary_ip) $FQDN $HOSTNAME
fi

system_set_timezone "America/Toronto"

# Setup iptable rules
echo "Setting iptable rules"
cp "$DIR/iptables.firewall.rules" /etc/
cp "$DIR/firewall" /etc/network/if-up.d/firewall
iptables-restore < /etc/iptables.firewall.rules

# Add sudo users (Must have a public key include identical to the user. Example "name.pub")
add_user "dougan"
add_user "vermeulen"

echo "Editing sshd config file"
edit_sshd_config
echo "Removing roots ssh key"
rm -f -r /root/.ssh
echo "Removing provision folder"
rm -f -r "$DIR"
echo ""