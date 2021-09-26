# OKD AIO

Single node OpenShift cluster deployement

## Prerequisites:

1. System Requirements:
- CPU: 4
- Memory: 8 GB
- Storage: 40 GB

## Installation

1. Update okd host inventory in `inventory/hosts`

2. Update OKD release info `oc_release` and `oc_binary` var in `inventory/group_vars/all.yml`

3. Setup OKD host
```bash
ansible-playbook -i inventory/hosts okd.yml
```

4. Connect to OKD server over ssh and run below command to install OKD
```bash
oc cluster up --skip-registry-check=true --public-hostname=<OKD Host IP>
```
