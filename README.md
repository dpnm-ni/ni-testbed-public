# NI-testbed

Testbed for NI.

## Testbed topology
```
 +------------+            +------------+
 | Controller |            | Monitoring |
 +-----+------+            +-----+------+
       |                         |
-------++-------------+----------+------+-------- Network
        |             |                 |
 +------+----+  +-----+-----+      +----+------+
 | Compute 1 |  | Compute 2 | ...  | Compute N |
 +-----------+  +-----------+      +-----------+

```

## Installation

### Clone the repo
This repo has several submodules.
```bash
git clone https://github.com/tu-nv/ni-testbed
git submodule update --init --recursive
```
### Prepare env
#### NI testbed with VMs
We recommend (as we only tested on) Ubuntu 18.04 LTS kernel.

- Install vagrant.
    ```bash
    wget https://releases.hashicorp.com/vagrant/2.2.8/vagrant_2.2.8_x86_64.deb
    sudo apt install ./vagrant_2.2.8_x86_64.deb
    ```
- Ensure `kvm` and `nested virtualization` are enabled, then [install qemu and libvirt](https://help.ubuntu.com/lts/serverguide/libvirt.html.en).
- Install [vagrant-libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt).
- Install OpenvSwitch and create bridge `ovsbr0`
    ```bash
    sudo apt install openvswitch-switch
    sudo ovs-vsctl add-br ovsbr0
    sudo ifconfig ovsbr0 192.168.3.1/24 up
    ```
- Provide internet access to `ovsbr0` network
    ```bash
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo iptables -t nat -I POSTROUTING -s 192.168.3.0/24 -j MASQUERADE
    sudo iptables -P FORWARD ACCEPT
    sudo iptables -t nat -P POSTROUTING ACCEPT
    ```
- Provision VMs.
    ```bash
    vagrant up --provider=libvirt --no-parallel
    ```

#### NI testbed with physical servers
If you use physical servers instead of VMs, prepair nodes as described in testbed topology. In our setup, all node run Ubuntu 16.04 server. Nodes should support KVM.

### Install devstack
- Install ansible 2.7 via `pip` (install as root) and `sshpass`:
    ```bash
    sudo apt install -y python-pip sshpass
    sudo pip install ansible==2.7.16
    ```
- Use vagrant inventory as the example and modify to suit your custom setup.
    ```bash
    cd inventories
    cp vagrant your_inventory_file
    ```
- Bootstrap
    ```bash
    ansible-playbook -i inventories/<your_inventory_file> bootstrap.yml
    ```
- Setup devstack
    ```bash
    ansible-playbook -i inventories/<your_inventory_file> openstack.yml
    ```

### Add more compute node to the cluster
- Add an entry of new compute node to the equivalent intentory file
    ```
    [computes]
    141.223.xx.xx HOST_NAME='NI-Compute-xx-xx' DATA_INTERFACE='<if_name>'
    ```
- Run ansible
    ```bash
    ansible-playbook -i inventories/physical_tesbed_001 openstack.yml --limit 141.223.xx.xx
    ```

### Firewall
Currently, we applied some firewall rules to the monitoring node. Check roles/firewall for details.

### Issues
- Currenly, Graylog requires manual adding rsyslog input by going to `Dashboard -> System/Inputs`.
- If use `networking-ovs-dpdk` then need to setup [reserved_huge_pages](https://bugzilla.redhat.com/show_bug.cgi?id=1517004#c24), otherwise there will be error `Insufficient free host memory pages`. Custom [conf file](roles/computes/templates/local.conf.j2) to set `reserved_huge_pages`.
