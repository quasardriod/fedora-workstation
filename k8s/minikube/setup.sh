#!/usr/bin/env bash

ansible_repo_pkg="centos-release-ansible-29"
mkube_extra_config="kubelet.cgroup-driver=systemd"

APPS_CODE_DIR="$PWD/roles/app-deployment/files"
CON_ENGINE=docker

PYTHON_APP_DIR="$APPS_CODE_DIR/hello-python"
PYTHON_IMAGE="hello-python"

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

build_image(){
    # this function needs two args
    # $1 - Application dir contains dockerfile and code
    # $2 - Image name
    app_dir=$1
    app_image=$2
    if [ -z $app_dir ] || [ -a $app_image ];then
        echo "app_dir & app_image can't be empty" && exit 1
    fi

    [ ! -d $app_dir ] && echo "$app_dir does not exists" && exit 1

    echo
    echo "Building application image..."
    echo

    if ! $CON_ENGINE images |egrep -qi $app_image; then
      cd $app_dir/app
      $CON_ENGINE build -f Dockerfile -t $app_image .
    else
      echo "Found existing $app_image image..."
      read -p "Rebuild $app_image image [y/N]: " choice
      if [ "$choice" == "y" ] || [ "$choice" == "Y" ];then
        cd $app_dir
        $CON_ENGINE build -f Dockerfile -t $app_image .
      elif [ "$choice" == "n" ] || [ "$choice" == "N" ] || [ -z "$choice" ];then
        echo "Good. Application will be deployed using existing $app_image image!"
      else
        echo "Wrong choice" && exit 1
      fi
    fi
}

deploy_app_k8s(){
  # this function needs two args
  # $1 - Application dir contains dockerfile and code
  app_dir=$1
  echo
  echo "Applying config in kubernetes..."
  echo
  cd $app_dir/kubernetes
  kubectl apply -f deployment.yaml
  kubectl get pods
}

run_application(){
  echo
  echo "Applications avaiable to test..."
  echo "
    1. Python Application
    2. Nginx web server
    3. Apache web server
  "
  echo
  read -p "Select option: " choice
  if [ "$choice" == "1" ];then
    build_image $PYTHON_APP_DIR/app $PYTHON_IMAGE
    deploy_app_k8s $PYTHON_APP_DIR
  fi
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
