#!/usr/bin/env bash

# Script Arguments:
# $1 -  Allinone node IP adddress
# $2 -  Interface for Vlan type networks
# $3 -  Physical network for Vlan type networks interface
ALLINONE_IP=$1

cp /vagrant/provisioning/local.conf.base devstack/local.conf

# Get the IP address
ipaddress=$(ip -4 addr show eth1 | grep -oP "(?<=inet ).*(?=/)")

# Adjust some things in local.conf
cat << DEVSTACKEOF >> devstack/local.conf

# Set this host's IP
HOST_IP=$ipaddress

# Enable services to be executed in compute node
ENABLED_SERVICES=neutron,q-agt,q-l3,q-meta

# Set the controller's IP
SERVICE_HOST=$ALLINONE_IP
MYSQL_HOST=$ALLINONE_IP
RABBIT_HOST=$ALLINONE_IP
Q_HOST=$ALLINONE_IP
GLANCE_HOSTPORT=$ALLINONE_IP:9292

[[post-config|/\$Q_PLUGIN_CONF_FILE]]
[ovs]
local_ip=$ipaddress

[agent]
tunnel_types=vxlan
l2_population=True
enable_distributed_routing=True

[[post-config|\$Q_L3_CONF_FILE]]
[DEFAULT]
agent_mode=dvr_snat
router_delete_namespaces=True
DEVSTACKEOF

devstack/stack.sh