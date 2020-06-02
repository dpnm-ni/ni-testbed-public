#!/bin/bash
#
# since vagrant snapshot does not work with libvirt-vagrant,
# we use a custom script to provide snapshot functions
#

set -e
set -x

cd "$(dirname "$0")" && cd ..

backup_f=false
restore_f=false

print_usage () {
    echo "script usage: $(basename $0) [-b] [-r]"
    echo "-b: create live snapshot"
    echo "-r: restore snapshot"
}

while getopts ':br' OPTION; do
    case "$OPTION" in
        b)
            backup_f=true
            ;;
        r)
            restore_f=true
            ;;
        ?)
            print_usage
            exit
            ;;
    esac
done

if [[ $backup_f == $restore_f ]]; then
    echo "error: should have either -b or -r flag, but not both"
    print_usage
    exit 1
fi

# libvirt-vagrant use the name of the top folder as a prefix for VM names
PREFIX=${PWD##*/}

for VM in `virsh list | grep "$PREFIX" | awk '{print $2}'`; do
    SNAP_NAME=${VM}-snap
    if $backup_f; then
        if $(virsh snapshot-list $VM | grep -qwi $SNAP_NAME); then
            virsh snapshot-delete $VM --current
        fi
        # TODO: how to have a live snapshot with both memory and disk bankup?
        virsh snapshot-create-as $VM --name $SNAP_NAME --atomic
    fi

    if $restore_f; then
        virsh snapshot-revert $VM $SNAP_NAME
    fi
done
