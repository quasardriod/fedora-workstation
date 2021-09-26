# OpenStack deployment (Packstack on CentOS)

Deploy openstack proof of concept with one host `controller + compute` node in virtualized env.

## Prerequisites:

1. System Requirements:
- CPU: 4
- Memory: 8 GB
- Storage: 40 GB

2. Network Requirements:
- Two interfaces
  - First interface with internet access (external and control plane network for openstack)
  - Second interface with private network (Only to service VM traffic, internet access is not needed)


## Deployment

1. Update OpenStack host inventory in `inventory/hosts`

2. Update OpenStack release info `openstack_repo` var in `inventory/group_vars/all.yml`

3. Setup OpenStack host
```bash
ansible-playbook -i inventory/hosts packstack.yml --tags="pre-setup,install-openstack"
```

4. Connect to OpenStack server over ssh and run below command to install OpenStack
```bash
packstack --answer-file=/root/packstack-answers.text
```

5. Post config tasks
```bash
ansible-playbook -i inventory/hosts packstack.yml --tags="post-setup"
```
