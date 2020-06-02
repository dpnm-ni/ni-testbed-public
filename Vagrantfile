# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["LC_ALL"] = "en_US.UTF-8"

BOX_IMAGE = "peru/ubuntu-18.04-server-amd64"
CONTROL_SUBNET = "192.168.3"
DATA_SUBNET = "192.168.4"
EXPOSE_PORT_DIFF = 0
COMPUTE_COUNT = 2
COMPUTE_CPU_COUNT = 6
COMPUTE_RAM = 8192
STACK_DIR = "/opt/stack"
# for dpdk test, use e1000 instead of virtio
# see: https://bugs.launchpad.net/networking-ovs-dpdk/+bug/1704279
NIC_TYPE = "virtio"

# vagrant use eth0 for NAT. Thus reroute everything to eth1
# also use resolvconf & ifupdown instead of netplan because somehow devstack (br-ex)
# does not work well with netplan configuration
$net_config = <<-SCRIPT
    apt update
    apt -y install resolvconf ifupdown net-tools
    apt -y remove netplan.io

    ip route del default
    ip route add default via #{CONTROL_SUBNET}.1

    echo nameserver 8.8.8.8 >> /etc/resolvconf/resolv.conf.d/head
    sudo service resolvconf restart
SCRIPT

Vagrant.configure("2") do |config|
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.box = BOX_IMAGE

    # https://superuser.com/questions/1160025/how-to-solve-ttyname-failed-inappropriate-ioctl-for-device-in-vagrant
    config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

    config.vm.provision "net_config", type: "shell", inline: $net_config

    config.vm.provider :libvirt do |libvirt|
        libvirt.nic_model_type = NIC_TYPE
        libvirt.nested = true
        libvirt.cpu_mode = "host-passthrough"
        libvirt.kvm_hidden = true
        libvirt.features = ['acpi', 'apic', 'pae', 'kvm' ]
        libvirt.cpu_feature :name => 'vmx', :policy => 'require'
    end

    config.vm.define "controller" do |controller|
        controller.vm.hostname = "controller"
        controller.vm.network "forwarded_port",guest: 80, host: 8010 + EXPOSE_PORT_DIFF, host_ip: "0.0.0.0"
        controller.vm.network "forwarded_port", guest: 6080, host: 6080 + EXPOSE_PORT_DIFF, host_ip: "0.0.0.0"
        controller.vm.network :private_network,
            :ip => "#{CONTROL_SUBNET}.11",
            :libvirt__dhcp_enabled => false
        controller.vm.network :private_network,
            :ip => "#{DATA_SUBNET}.11",
            :libvirt__dhcp_enabled => false
        controller.vm.provider :libvirt do |libvirt|
            libvirt.cpus = 2
            libvirt.memory = 8192
        end
    end

    (1..COMPUTE_COUNT).each do |i|
        config.vm.define "compute#{i}" do |compute|
            compute.vm.hostname = "compute#{i}"
            compute.vm.network :private_network,
                :ip => "#{CONTROL_SUBNET}.#{i + 30}",
                :libvirt__dhcp_enabled => false
            compute.vm.network :private_network,
                :ip => "#{DATA_SUBNET}.#{i + 30}",
                :libvirt__dhcp_enabled => false
            compute.vm.provider :libvirt do |libvirt|
                libvirt.cpus = COMPUTE_CPU_COUNT
                libvirt.memory = COMPUTE_RAM
            end
        end
    end

    config.vm.define "monitoring" do |monitoring|
        monitoring.vm.hostname = "monitoring"
        monitoring.vm.network "forwarded_port", guest: 9000, host: 9000 + EXPOSE_PORT_DIFF, host_ip: "0.0.0.0"
        monitoring.vm.network "forwarded_port", guest: 3000, host: 3000 + EXPOSE_PORT_DIFF, host_ip: "0.0.0.0"
        monitoring.vm.network "forwarded_port", guest: 8181, host: 8181 + EXPOSE_PORT_DIFF, host_ip: "0.0.0.0"
        monitoring.vm.network "forwarded_port", guest: 8383, host: 8383 + EXPOSE_PORT_DIFF, host_ip: "0.0.0.0"
        monitoring.vm.network :private_network,
            :ip => "#{CONTROL_SUBNET}.21",
            :libvirt__dhcp_enabled => false
        monitoring.vm.network :private_network,
            :ip => "#{DATA_SUBNET}.21",
            :libvirt__dhcp_enabled => false
        monitoring.vm.provider :libvirt do |libvirt|
            libvirt.cpus = 2
            libvirt.memory = 4096
        end
    end
end
