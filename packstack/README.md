# OpenStack deployment (Packstack on CentOS)

Deploy openstack proof of concept with one host `controller + compute` node in virtualized env.

## Pre-requisites:

1. System Requirements:
CPU: 4
Memory: 8 GB
Storage: 40 GB

2. Network Requirements:
- Two interfaces
  - First interface with internet access (external and control plane network for openstack)
  - Second interface with private network (Only to service VM traffic, internet access is not needed)


## Deployment

1. Update Openstack host information in `inventory/hosts`

2. Update Openstack release info `openstack_repo` var in `inventory/group_vars/all.yml`

3. Setup Openstack host
```bash
ansible-playbook -i inventory/hosts packstack.yml

4. Connect to Openstack server and run below command
```bash

```
