# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'getoptlong'

is_ci=false

opts = GetoptLong.new([ '--ci', GetoptLong::OPTIONAL_ARGUMENT ])
opts.ordering=(GetoptLong::REQUIRE_ORDER)
opts.each do |opt, arg|
    case opt
    when '--ci'
        is_ci=true
    end
end

ENV["LC_ALL"] = "C"
BOX_IMAGE = "peru/ubuntu-18.04-server-amd64"
VM_POSTFIX = ''
CONTROL_SUBNET = "192.168.3"
DATA_SUBNET = "192.168.4"
is_expose_port = true
COMPUTE_COUNT = 2
COMPUTE_CPU_COUNT = 8
COMPUTE_RAM = 16384
STACK_DIR = "/opt/stack"
# for dpdk test, use e1000 instead of virtio
# see: https://bugs.launchpad.net/networking-ovs-dpdk/+bug/1704279
NIC_TYPE = "virtio"
OVSBR_NAME = "ovsbr0"

if is_ci
    VM_POSTFIX = '-ci'
    OVSBR_NAME = 'ovsbr0-ci'
    CONTROL_SUBNET = "192.168.5"
    DATA_SUBNET = "192.168.6"
    is_expose_port = false
    NIC_TYPE = "e1000"
end


# vagrant use eth0 for NAT. Thus reroute everything to eth1
# also use resolvconf & ifupdown instead of netplan because somehow devstack (br-ex)
# does not work well with netplan configuration
$config = <<-SCRIPT

    apt-get update

    # install python2
    apt-get -y install python

    # correct default route
    wget --quiet https://github.com/mikefarah/yq/releases/download/3.3.2/yq_linux_amd64 -O yq && chmod a+x yq
    ./yq w -i /etc/netplan/50-vagrant.yaml network.ethernets.eth1.gateway4 #{CONTROL_SUBNET}.1
    netplan apply

    # enable virsh tty console
    systemctl enable serial-getty@ttyS0.service
    systemctl start serial-getty@ttyS0.service
SCRIPT

Vagrant.configure("2") do |config|
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.box = BOX_IMAGE
    # https://superuser.com/questions/1160025/how-to-solve-ttyname-failed-inappropriate-ioctl-for-device-in-vagrant
    config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
    config.vm.provision "config", type: "shell", inline: $config

    config.vm.provider :libvirt do |libvirt|
        libvirt.nic_model_type = NIC_TYPE
        libvirt.nested = true
        libvirt.cpu_mode = "host-passthrough"
        libvirt.kvm_hidden = true
        libvirt.management_network_mode = 'none'
        libvirt.features = ['acpi', 'apic', 'pae', 'kvm' ]
        libvirt.cpu_feature :name => 'vmx', :policy => 'require'
    end

    config.vm.define "controller#{VM_POSTFIX}" do |controller|
        controller.vm.hostname = "controller#{VM_POSTFIX}"
        if is_expose_port
            controller.vm.network "forwarded_port",guest: 80, host: 8000, host_ip: "0.0.0.0"
            controller.vm.network "forwarded_port", guest: 6080, host: 6080, host_ip: "0.0.0.0"
        end
        controller.vm.network :public_network,
            :ip => "#{CONTROL_SUBNET}.11",
            :dev => "#{OVSBR_NAME}",
            :type => 'bridge',
            :ovs => true
        controller.vm.provider :libvirt do |libvirt|
            libvirt.cpus = 4
            libvirt.memory = 8192
        end
    end

    (1..COMPUTE_COUNT).each do |i|
        config.vm.define "compute#{i}#{VM_POSTFIX}" do |compute|
            compute.vm.hostname = "compute#{i}#{VM_POSTFIX}"
            compute.vm.network :public_network,
                :ip => "#{CONTROL_SUBNET}.#{i + 30}",
                :dev => "#{OVSBR_NAME}",
                :type => 'bridge',
                :ovs => true
            compute.vm.provider :libvirt do |libvirt|
                libvirt.cpus = COMPUTE_CPU_COUNT
                libvirt.memory = COMPUTE_RAM
            end
        end
    end

    config.vm.define "monitoring#{VM_POSTFIX}" do |monitoring|
        monitoring.vm.hostname = "monitoring#{VM_POSTFIX}"
        if is_expose_port
            monitoring.vm.network "forwarded_port", guest: 9000, host: 9000, host_ip: "0.0.0.0"
            monitoring.vm.network "forwarded_port", guest: 9001, host: 9001, host_ip: "0.0.0.0"
            monitoring.vm.network "forwarded_port", guest: 3000, host: 3000, host_ip: "0.0.0.0"
            monitoring.vm.network "forwarded_port", guest: 8181, host: 8181, host_ip: "0.0.0.0"
            monitoring.vm.network "forwarded_port", guest: 8383, host: 8383, host_ip: "0.0.0.0"
        end
        monitoring.vm.network :public_network,
            :ip => "#{CONTROL_SUBNET}.21",
            :dev => "#{OVSBR_NAME}",
            :type => 'bridge',
            :ovs => true
        monitoring.vm.provider :libvirt do |libvirt|
            libvirt.cpus = 4
            libvirt.memory = 8192
        end
    end
end
