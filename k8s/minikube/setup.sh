#!/usr/bin/env bash

ansible_repo_pkg="centos-release-ansible-29"
mkube_extra_config="kubelet.cgroup-driver=systemd"

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

install_docker(){
  ansible-playbook minikube.yml --tags="docker"
}

k8s_tools(){
  ansible-playbook minikube.yml --tags="k8s-tools"
}

install_minikube(){
  #echo
  #echo "Download minikube binaries"
  #ansible-playbook minikube.yml --tags="minikube"
  echo
  echo "Start minikube setup..."
  echo
  if dmidecode -t system|egrep -qw "\s+Manufacturer:\sQEMU";then
    minikube start --driver=none
  fi
}

pod_testing(){
  echo
  echo "Applications avaiable to test..."
  echo "
    1. Nginx web server
    2. Apache web server
    3. Python Application
  "
  echo
  read -p "Select option: " choice
  if [ "$choice" == "1" ];then
    echo
    echo "Building app..."
    echo
  fi
}

help(){
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


while getopts 'adhmpt' opt; do
	case $opt in
		a) install_ansible;;
    d) install_docker;;
    h) help;;
    m) install_minikube;;
    p) pod_testing;;
    t) k8s_tools;;
		\?|*)	echo "Invalid Option: -$OPTARG" && usage;;
	esac
done
