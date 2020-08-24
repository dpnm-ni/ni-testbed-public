#!/bin/bash
#
# change vagrant parameters for CI test
#

set -e
set -x

cd "$(dirname "$0")"

sed -e 's/192.168.3/192.168.5/g' \
     ../inventories/vagrant > ../inventories/vagrant_ci

sed -e 's/192.168.3/192.168.5/g' \
    -e 's/192.168.4/192.168.6/g' \
        ../inventories/vagrant_dpdk > ../inventories/vagrant_dpdk_ci

