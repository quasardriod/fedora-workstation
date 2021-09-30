#!/usr/bin/env bash
ansible_repo_pkg="centos-release-ansible-29"
inventory="inventory/hosts"

install_ansible(){
  if ! which ansible > /dev/null 2>&1;then
    echo
    echo "Installing ansible..."
    if cat /etc/redhat-release|egrep -q ^CentOS;then
      dnf install $ansible_repo_pkg -y
      [ $? != 0 ] && echo "Failed to install $ansible_repo_pkg" && exit 1

      dnf install ansible -y
      if ! rpm -q ansible > /dev/null 2>&1;then
        echo "Error! ansible rpm not found" && exit
      fi
    fi
  else
    echo "Ansible is already installed" && exit 0
  fi
}

pre_setup(){
  ansible-playbook -i inventory packstack
}
usages(){
	echo
  echo " -a Install Ansible"
  echo " -d Install Docker Engine"
  echo " -h Show this help message"
  echo " -m Install Minikube"
  echo " -t Install K8s tools"
  echo " -p Building app in kubernetes cluster"
  echo
	exit 0
}


while getopts 'adhmrt' opt; do
  case $opt in
    a) install_ansible;;
    d) install_docker;;
    h) usages;;
    m) install_minikube;;
    r) run_application;;
    t) k8s_tools;;
    \?|*) echo "Invalid Option: -$OPTARG" && usages;;
  esac
done
