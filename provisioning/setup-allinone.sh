#!/usr/bin/env bash

cp /vagrant/provisioning/local.conf.base devstack/local.conf
DESIGNATE_ZONE=my-domain.org.

# Get the IP address
ipaddress=$(ip -4 addr show eth1 | grep -oP "(?<=inet ).*(?=/)")

# Adjust local.conf
cat << DEVSTACKEOF >> devstack/local.conf

# Set this host's IP
HOST_IP=$ipaddress

# Set firewall driver
FW_DRV=openvswitch

# Enable Neutron as the networking service
disable_service n-net
enable_service placement-api
enable_service neutron
enable_service neutron-api
#enable_service q-svc
enable_service q-meta
enable_service q-agt
enable_service q-dhcp
enable_service q-l3
enable_service tempest
enable_plugin designate https://git.openstack.org/openstack/designate
enable_plugin neutron-tempest-plugin https://git.openstack.org/openstack/neutron-tempest-plugin
enable_plugin osprofiler https://git.openstack.org/openstack/osprofiler
OSPROFILER_COLLECTOR=redis

[[post-config|\$NEUTRON_CONF]]
[DEFAULT]
service_plugins=router,segments,qos,trunk
allow_overlapping_ips=True
router_distributed=True
l3_ha=True
l3_ha_net_cidr=169.254.192.0/18
max_l3_agents_per_router=3
dns_domain=$DESIGNATE_ZONE 
external_dns_driver=designate

[designate]
url=http://$ipaddress:9001/v2
allow_reverse_dns_lookup=True
ipv4_ptr_zone_prefix_size=24
ipv6_ptr_zone_prefix_size=116
auth_type = password
auth_url = http://$ipaddress/identity
project_domain_name = default
user_domain_name = default
username = neutron
password = devstack
project_name = service

[[post-config|/\$Q_PLUGIN_CONF_FILE]]
[ml2]
type_drivers=flat,vxlan
tenant_network_types=vxlan
mechanism_drivers=openvswitch,l2population
extension_drivers=port_security,dns_domain_ports,qos

[securitygroup]
firewall_driver=$FW_DRV
enable_security_group=True

[ml2_type_vxlan]
vni_ranges=1000:1999

[ovs]
local_ip=$ipaddress

[vxlan]
enable_vxlan=True
l2_population=True
local_ip=$ipaddress

[agent]
tunnel_types=vxlan
l2_population=True
enable_distributed_routing=True
extensions=qos
dscp=8

[[post-config|\$Q_L3_CONF_FILE]]
[DEFAULT]
interface_driver=openvswitch
agent_mode=dvr_snat
router_delete_namespaces=True
ha_vrrp_auth_password=devstack

[[post-config|\$Q_DHCP_CONF_FILE]]
[DEFAULT]
dhcp_delete_namespaces=True
enable_isolated_metadata=True

[[post-config|\$KEYSTONE_CONF]]
[token]
expiration=30000000
DEVSTACKEOF

devstack/stack.sh

source devstack/openrc demo demo
openstack zone create --email malavall@us.ibm.com $DESIGNATE_ZONE

source devstack/openrc admin admin
NET_ID=$(neutron net-create --provider:network_type=vxlan \
    --provider:segmentation_id=2016 --shared --dns-domain $DESIGNATE_ZONE \
    external | grep ' id ' | awk 'BEGIN{} {print $4} END{}')
neutron subnet-create --ip_version 4 --name external-subnet $NET_ID \
    172.31.251.0/24
neutron subnet-create --ip_version 6 --name ipv6-external-subnet $NET_ID \
    fd5e:7a6b:1a62::/64
