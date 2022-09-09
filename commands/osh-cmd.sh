#!/bin/bash

KEYPAIR_NAME="osp-key"

create_keypair(){
	if openstack keypair show $KEYPAIR_NAME

}

usages(){
	echo
  echo " -k Create Keypair"
  echo " -h Show this help message"
  echo
	exit 0
}


while getopts 'kh' opt; do
  case $opt in
    k) create_keypair;;
    h) usages;;
    \?|*) echo "Invalid Option: -$OPTARG" && usages;;
  esac
done
