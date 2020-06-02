#!/bin/bash
#
# Follow devstack tutorial

set -x

echo "Running local.sh"
source openrc

# Commented out. See https://bugs.launchpad.net/devstack/+bug/1783576
# for i in `seq 2 10`; do /usr/local/bin/nova-manage fixed reserve 10.4.128.$i; done
# for i in `seq 2 10`; do /opt/stack/nova/bin/nova-manage fixed reserve 10.4.128.$i; done

# enable icmp and ssh for default security group for demo user. For admin user, add manually,
# because there are multiple default security group
if is_service_enabled n-api; then
    for user in demo; do
        source openrc "$user" "$user"
        openstack security group rule create --proto icmp --dst-port -1 --remote-ip 0.0.0.0/0 default
        openstack security group rule create --proto tcp --dst-port 22 --remote-ip 0.0.0.0/0 default
    done
fi
