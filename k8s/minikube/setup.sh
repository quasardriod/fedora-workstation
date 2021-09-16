#!/usr/bin/env bash

ansible_repo_pkg="centos-release-ansible-29"

if ! which ansible > /dev/null 2>&1;
  echo
  echo "Install ansible..."
  if cat /etc/redhat-release|egrep -q ^CentOS;then
    dnf install $ansible_repo_pkg -y -q
    [ $? != 0 ] && echo "Failed to install $ansible_repo_pkg" && exit 1

    dnf install ansible -y -q
    if ! rpm -q ansible > /dev/null 2>&1;
      echo "Error! ansible rpm not found" && exit
    fi
  fi
fi
