#!/usr/bin/env bash

# Script Arguments:
# $1 -  Allinone node IP adddress
ALLINONE_IP=$1

cp /vagrant/provisioning/local.conf.base devstack/local.conf

# Get the IP address
ipaddress=$(ip -4 addr show eth1 | grep -oP "(?<=inet ).*(?=/)")

# Adjust some things in local.conf
cat << DEVSTACKEOF >> devstack/local.conf

# Set this host's IP
HOST_IP=$ipaddress

# Enable services to be executed in compute node
ENABLED_SERVICES=n-cpu,neutron,n-novnc,q-agt,placement-api

# Set the controller's IP
SERVICE_HOST=$ALLINONE_IP
MYSQL_HOST=$ALLINONE_IP
RABBIT_HOST=$ALLINONE_IP
Q_HOST=$ALLINONE_IP
GLANCE_HOSTPORT=$ALLINONE_IP:9292
VNCSERVER_PROXYCLIENT_ADDRESS=$ipaddress
VNCSERVER_LISTEN=0.0.0.0

# Enable linuxbridge agent 
Q_AGENT=linuxbridge

[[post-config|/\$Q_PLUGIN_CONF_FILE]]

[vxlan]
enable_vxlan=True
l2_population=True
local_ip=$ipaddress
udp_dstport=4789
DEVSTACKEOF

devstack/stack.sh
