#!/bin/bash
#
# change vagrant parameters for CI test
#

set -e
set -x

cd "$(dirname "$0")"

sed -i 's/^CONTROL_SUBNET.*/CONTROL_SUBNET = "192.168.5"/;
        s/^DATA_SUBNET.*/DATA_SUBNET = "192.168.6"/;
        s/^COMPUTE_CPU_COUNT.*/COMPUTE_CPU_COUNT = 6/;
        s/^COMPUTE_RAM.*/COMPUTE_RAM = 8192/;
        s/^EXPOSE_PORT_DIFF.*/EXPOSE_PORT_DIFF = 10000/;
        s/^NIC_TYPE.*/NIC_TYPE = "e1000"/
        ' ../Vagrantfile

sed -i 's/192.168.3/192.168.5/g' ../inventories/vagrant
sed -i 's/192.168.3/192.168.5/g;
        s/192.168.4/192.168.6/g
        ' ../inventories/vagrant_dpdk

# ensure internet access to VMs
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -I POSTROUTING -s 192.168.5.0/24 -j MASQUERADE
sudo iptables -P FORWARD ACCEPT
sudo iptables -t nat -P POSTROUTING ACCEPT

# remove duplicate iptables rules
sudo iptables-save | uniq | sudo iptables-restore
