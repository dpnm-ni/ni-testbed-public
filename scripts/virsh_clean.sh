#!/bin/bash
#
# destroy and clean all VMs
#

set -e
set -x

for VM in `virsh list --name | grep '_ci'`; do
    virsh destroy $VM
    virsh undefine $VM --remove-all-storage
done
# for remaining shutdown VMs
for VM in `virsh list --name --all | grep '_ci'`; do
    virsh undefine $VM --remove-all-storage
done
