# OpenStack deployment (Packstack on CentOS)

Deploy OpenStack proof of concept with one host `controller + compute` node in virtualized env.

## Prerequisites:

1. System Requirements:
- CPU: 4
- Memory: 8 GB
- Storage: 40 GB

2. Network Requirements:
- Two Interfaces
  - First interface with internet access (external and control plane network for openstack)
  - Second interface with private network (Only to serve VM traffic, internet access is not needed)

3. Enable nested virtualization if VMs(compute nodes) are hosts in:
- KVM: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_virtualization/creating-nested-virtual-machines_configuring-and-managing-virtualization

## Installation

1. Update OpenStack host inventory in `inventory/hosts`

2. Update OpenStack release info `openstack_repo` var in `inventory/group_vars/all.yml`

3. Enable and Disable additional openstack projects using `openstack_projects` var in `inventory/group_vars/all.yml`

4. Setup OpenStack host
```bash
ansible-playbook -i inventory/hosts packstack.yml
```

5. Connect to OpenStack server over ssh and run below command to install OpenStack
```bash
packstack --answer-file=/root/packstack-answers.text
```

# Not Needed, will remove later
6. Post config tasks
```bash
ansible-playbook -i inventory/hosts packstack.yml --tags="post-setup"
```
