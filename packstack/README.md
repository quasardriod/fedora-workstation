# OpenStack deployment (Packstack on CentOS)

Deploy openstack proof of concept with one controller (and compute) node in virtualized env.

## Pre-requisites:

1. System Requirements:
CPU: 4
Memory: 8 GB
Storage: 40 GB

2. Network Requirements:
- Two interfaces
  - First interface with internet access (external and control plane network for openstack)
  - Second interface with private network (Only to service VM traffic, internet access is not needed)
