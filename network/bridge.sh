#!/bin/bash

set -e -o pipefail

bridge_name=br0

# Create a linux bridge

if ! nmcli con show $bridge_name > /dev/null 2>&1;then
	nmcli con add ifname $bridge_name type bridge con-name $bridge_name
else
	echo "$bridge_name already exists. Skipping..." 
fi

eth_name=$(ip a|egrep ^[0-9]|awk '{print $2}'|egrep -v "^lo|^wl|^vi|^$bridge_name"|cut -d':' -f1)
echo "Found ethernet: $eth_name"

# Add a physical interface as slave(wired interface)
if ! nmcli con show bridge-slave-$eth_name > /dev/null 2>&1;then
	nmcli con add type bridge-slave ifname $eth_name master $bridge_name
else
	echo "bridge-slave-$eth_name connection alredy presented. Skipping..."
fi

# List connection
echo
echo "--- Connections ---"
echo
nmcli con show|egrep "$bridge_name|$eth_name"
