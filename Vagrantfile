# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'ipaddr'

vagrant_config = YAML.load_file("provisioning/virtualbox.conf.yml")

Vagrant.configure(2) do |config|
  config.vm.box = vagrant_config['box']

  if Vagrant.has_plugin?("vagrant-cachier")
    # Configure cached packages to be shared between instances of the same base box.
    # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
    config.cache.scope = :box
  end

  #config.vm.synced_folder
  config.vm.synced_folder File.expand_path("~/neutron"), "/opt/stack/neutron"
  config.vm.synced_folder File.expand_path("~/nova"), "/opt/stack/nova"

  # Bring up the Devstack allinone node on Virtualbox
  config.vm.define "allinone", primary: true do |allinone|
    allinone.vm.host_name = vagrant_config['allinone']['host_name']
    allinone.vm.network "private_network", ip: vagrant_config['allinone']['ip']
    allinone.vm.provision "shell", path: "provisioning/setup-base.sh", privileged: false
    allinone.vm.provision "shell", path: "provisioning/setup-allinone.sh", privileged: false
    allinone.vm.provider "virtualbox" do |vb|
       vb.memory = vagrant_config['allinone']['memory']
       vb.cpus = vagrant_config['allinone']['cpus']
       vb.customize [
           'modifyvm', :id,
           '--natdnshostresolver1', "on"
          ]
       vb.customize [
           "guestproperty", "set", :id,
           "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000
          ]
    end
  end

  # Bring up the first Devstack compute node on Virtualbox
  config.vm.define "compute1" do |compute1|
    compute1.vm.host_name = vagrant_config['compute1']['host_name']
    compute1.vm.network "private_network", ip: vagrant_config['compute1']['ip']
    compute1.vm.provision "shell", path: "provisioning/setup-base.sh", privileged: false
    compute1.vm.provision "shell", path: "provisioning/setup-compute.sh", privileged: false,
      :args => "#{vagrant_config['allinone']['ip']}"
    compute1.vm.provider "virtualbox" do |vb|
       vb.memory = vagrant_config['compute1']['memory']
       vb.cpus = vagrant_config['compute1']['cpus']
       vb.customize [
           'modifyvm', :id,
           '--natdnshostresolver1', "on"
          ]
       vb.customize [
           "guestproperty", "set", :id,
           "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000
          ]
    end
  end

  # Bring up the network node on Virtualbox enabled also as
  config.vm.define "network" do |network|
    network.vm.host_name = vagrant_config['network']['host_name']
    network.vm.network "private_network", ip: vagrant_config['network']['ip']
    network.vm.provision "shell", path: "provisioning/setup-base.sh", privileged: false
    network.vm.provision "shell", path: "provisioning//setup-network.sh", privileged: false,
      :args => "#{vagrant_config['allinone']['ip']}"
    network.vm.provider "virtualbox" do |vb|
       vb.memory = vagrant_config['network']['memory']
       vb.cpus = vagrant_config['network']['cpus']
       vb.customize [
           'modifyvm', :id,
           '--natdnshostresolver1', "on"
          ]
       vb.customize [
           "guestproperty", "set", :id,
           "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000
          ]
    end
  end
  # Execute sudo nova-manage cell_v2 discover_hosts --verbose in the allinone
  # node after the entire cluster is up
end
