#!/bin/bash
#
# destroy and clean all VMs
#

set -e
set -x

# drone-exec runner clone repo into src folder,
# vagrant up then uses src as the prefix for VM name
for VM in `virsh list --name | grep 'src'`; do
    virsh destroy $VM
    virsh undefine $VM --remove-all-storage
done
# for remaining shutdown VMs
for VM in `virsh list --name --all | grep 'src'`; do
    virsh undefine $VM --remove-all-storage
done
