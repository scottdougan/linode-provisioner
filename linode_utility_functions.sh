#!/bin/bash 
#Author: Scott Dougan
#Date: September 22, 2015
#Version: 1.1
#Utility functions for Linode CLI.

function linode_info {
	local HOSTNAME="$1"

    if [ -z "$HOSTNAME" ]; then
        echo -e "\nFAILED: Linode Info - hostname undefined\n" 1>&2
        kill -s TERM $TOP_PID
    fi

    local RESPONSE=$(linode -o linode -a show --l $HOSTNAME 2>&1)
    local SUCCESS=$(echo $RESPONSE | grep -o -E "label: $HOSTNAME")
	if [ -z "$SUCCESS" ]; then
		echo -e "\nFAILED: $RESPONSE" 1>&2
		echo  "Try Running \"linode configure\"" 1>&2
		kill -s TERM $TOP_PID
	fi
	echo $RESPONSE
}

function linode_ip {
	local HOSTNAME="$1"

    if [ -z "$HOSTNAME" ]; then
        echo -e "\nFAILED: Linode IP - hostname undefined\n" 1>&2
        kill -s TERM $TOP_PID
    fi
	echo $(linode_info $HOSTNAME |  grep -o -E "ips: [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sed 's/ips: //')
}

function linode_status {
	local HOSTNAME="$1"

    if [ -z "$HOSTNAME" ]; then
        echo -e "\nFAILED: Linode Status - hostname undefined\n" 1>&2
        kill -s TERM $TOP_PID
    fi
	echo $(linode_info $HOSTNAME | grep -o -E "status: (running|stopped|brand new|being created|powered off)" | sed 's/status: //')
}

function linode_start {
    local HOSTNAME="$1"

    if [ -z "$HOSTNAME" ]; then
        echo -e "\nFAILED: Linode Start - hostname undefined\n" 1>&2
        kill -s TERM $TOP_PID
    fi
    echo $(linode -o linode -a start --l $HOSTNAME)

}

function wait_for_status_change {
    local HOSTNAME="$1"
    local CURRENT_STATUS="$2"

    if [ -z "$HOSTNAME" -o -z "$CURRENT_STATUS" ]; then
        echo -e "\nFAILED: Linode wait for status change - No hostname and/or current status\n" 1>&2
        kill -s TERM $TOP_PID
    fi
    
    echo -n "."
    while true; do 
        sleep 1
        if [[ "$(linode_status $HOSTNAME)" != "$CURRENT_STATUS" ]]; then 
            echo ""
            return 1
        fi
        echo -n "."
    done
}

function wait_for_ssh {
    local IP="$1"

    if [ -z "$IP" ]; then
        echo -e "\nFAILED: Linode wait for ssh - IP undefined\n" 1>&2
        kill -s TERM $TOP_PID
    fi

    while true; do 
        ssh -o StrictHostKeyChecking=no -q root@"$IP" exit
        if [ $? -eq 0 ]; then 
            echo ""
            break
        fi
        echo -n "."
        sleep 1
    done
}