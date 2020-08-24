#!/bin/bash
#
# bash script to run CI test
#

set -e
set -x

cd "$(dirname "$0")"

/bin/bash scripts/test_config.sh

vagrant --ci -- destroy -f
vagrant --ci -- up --provider=libvirt --no-parallel
ansible-playbook -i inventories/vagrant_ci bootstrap.yml
ansible-playbook -i inventories/vagrant_ci openstack.yml
# vagrant --ci -- destroy -f
