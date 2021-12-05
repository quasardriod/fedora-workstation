#!/usr/bin/env bash

rc_file="$HOME/keystonerc_admin"
endpoint_host="os-ctrl01.quasarstack.com"
region=RegionOne

[ ! -f $rc_file ] && echo "Error! $rc_file not found" && exit 1

if env |egrep -q ^OS_AUTH_URL;then
  source $rc_file
fi

declare -a endpoint_type
endpoint_type=(
  public
  admin
  internal
)

keystone_endpoint(){
  for ep_type in ${cluster_list[@]};do
    if ! openstack endpoint list |egrep keystone |egrep -q $ep_type|egrep -q $endpoint_host;then
      openstack endpoint create --region $region identity $ep_type https://$endpoint_host:5000
    fi
  done
}

keystone_endpoint
