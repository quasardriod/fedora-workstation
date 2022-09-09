#!/bin/bash

[ ! $USER == "root" ] && echo "Run program as root" && exit 1
[ "$PWD" != "$HOME" ] && echo "Copy script in $HOME and then run ./$0" && exit 1

: ${CLEAN_SETUP:="true"}								# if true, cleanup function will be called to delete existing minikune setup
: ${INSTALL_HORIZON:="true"}						# Needed to continue the 
: ${VALIDATE_UMBRELLA_CONFIG:="true"} 	# Run validate-umbrella-upgrade-config-changes-do-not-update-other-components.sh
: ${HELM_TESTS:="no"}										# Run helm tests
: ${CREATE_STACK:="no"}									# Create heat stack to test openstack

echo
echo "--> Following vars will change the course of the deployment:"
echo
echo "CLEAN_SETUP: $CLEAN_SETUP      # Delete existing minikube env" 
echo "VALIDATE_UMBRELLA_CONFIG: $VALIDATE_UMBRELLA_CONFIG		# Run test to validate umbrella upgrade config"
echo "HELM_TESTS: $HELM_TESTS        # Validate Openstack deployed services"
echo "CREATE_STACK: $CREATE_STACK    # Create stack and test deployment post installation"
echo
read -p "Continue[y/N]: " choice
if [ "${choice^^}" != "Y" ] || [ -z $choice ];then
	echo "Exiting..." && exit 1
fi

if ! lsb_release -a|egrep -q "Ubuntu 20.04";then
	echo "Host OS must be Ubuntu 20.04" && exit 1
fi

cleanup(){

if which minikube >/dev/null 2>&1;then
  if minikube status|egrep -q "^type:\sControl\sPlane";then
    minikube delete
  fi
fi
sed -i -e '/minikube/d' /etc/hosts
sed -i -e '/osh/d' /etc/hosts
sed -i -e '/svc.cluster.local/d' /etc/resolv.conf
sed -i -e '/^nameserver\s10.96.0.10/d' /etc/resolv.conf
rm -rf /etc/openstack/clouds.yaml
rm -rf /var/lib/minikube
rm -rf /tmp/mysql-data
rm -rf /etc/placement* /tmp/placement*
rm -rf /var/lib/nova* /tmp/nova* /ect/nova*
rm -rf /var/lib/neutron* /tmp/neutron* /etc/neutron*
rm -rf openstack-helm
rm -rf openstack-helm-infra
}

[ "$CLEAN_SETUP" == "true" ] && cleanup

: ${OSH_EXTRA_HELM_ARGS:="--timeout 20m"}
: ${OPENSTACK_RELEASE:='victoria'}
: ${CONTAINER_DISTRO_VERSION:='focal'}
: ${UPDATE_CALICO_VERSION:="true"}

# Tests take a lot longer but are an 
# important check before submitting for review
# RUN_HELM_TESTS='yes' 

# HOST NETWORKING
systemctl start systemd-resolved
echo "127.0.1.1 $(hostname)" | tee -a /etc/hosts
cp --remove-destination /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl disable systemd-resolved
systemctl stop systemd-resolved

cd ~
[ ! -d "openstack-helm" ] && git clone "https://review.opendev.org/openstack/openstack-helm"
[ ! -d "openstack-helm-infra" ] && git clone "https://review.opendev.org/openstack/openstack-helm-infra"

#check out any patchset you're testing out here, too
cd ~/openstack-helm

## FILE CHANGES
# insert kube DNS as first nameserver instead of entirely overwriting /etc/resolv.conf
#sed --in-place "/echo 'nameserver/c\  sudo bash -c \"sed -i -e '1inameserver 10.96.0.10' /etc/resolv.conf\"" ../openstack-helm-infra/tools/gate/deploy-k8s.sh

# Tweak $HOME/openstack-helm/tools/deployment/component/common/openstack.sh to install horizon	
if [ "$INSTALL_HORIZON" == "true" ];then
	
	# Create symlink for horizin in openstack-helm/openstack/charts
	[ ! -d horizon ] && echo "ERROR! openstack-helm/horizon not found" && exit 1
	ln -s ../../horizon openstack/charts/horizon
	
	[ ! -L openstack/charts/horizon ] && [ ! -f openstack/charts/horizon ] && \
		echo "ERROR! Failed to create horizon symlink in openstack-helm/openstack/charts/horizon" && exit 1

	# Add horizon chart in openstack-helm/openstack/Charts.yaml
	sed -i '/^description:\sA\schart\sfor\sopenstack\shelm\s*/i - name: horizon\n  repository: file:\/\/..\/horizon\n  version: ">0.1.0"\n  condition: horizon.enabled\n' openstack/Chart.yaml
	
	# Copy files from openstack-helm/horizon/values_overrides to openstack-helm/openstack/values_overrides/horizon/
	[ ! -d openstack/values_overrides/horizon ] && mkdir openstack/values_overrides/horizon && cp -rf horizon/values_overrides/* openstack/values_overrides/horizon/

	# Add horizon release group in openstack-helm/openstack/values.yaml
	sed -i -e '$a\\nhorizon:\n  release_group: horizon\n  enabled: true\n  helm3_hook: false' openstack/values.yaml

	# Add export OSH_EXTRA_HELM_ARGS_HORIZON in openstack-helm/tools/deployment/component/common/openstack.sh
	sed -i -e '/^export\sHELM_CHART_ROOT_PATH=/a : ${OSH_EXTRA_HELM_ARGS_HORIZON:="$(./tools/deployment/common/get-values-overrides.sh horizon subchart)"}' tools/deployment/component/common/openstack.sh
	
	sed -i '/^helm\supgrade\s--install/a \  ${OSH_EXTRA_HELM_ARGS_HORIZON} \\' tools/deployment/component/common/openstack.sh

	# Tweak openstack-helm/tools/gate/tests/validate-umbrella-upgrade-config-changes-do-not-update-other-components.sh to add horizon
	echo 'validate_only_expected_application_changes "horizon" "--set horizon.conf.horizon.log.file.level=WARN"' >> tools/gate/tests/validate-umbrella-upgrade-config-changes-do-not-update-other-components.sh 
fi




# Update calico version
if [ "$UPDATE_CALICO_VERSION" == "true" ];then
	echo
	echo "Updating calico version..."
	_CALICO_VERION="v3.24.0"
	_CALICO_CONFIG="https://raw.githubusercontent.com/projectcalico/calico/$_CALICO_VERION/manifests/calico.yaml"
	sed -i -e 's/https:\/\/docs.projectcalico.org\/archive\/"\${CALICO_VERSION}"\/manifests\/calico.yaml/\$CALICO_CONFIG/g' $HOME/openstack-helm-infra/tools/gate/deploy-k8s.sh
	CALICO_VERSION=$_CALICO_VERION CALICO_CONFIG=$_CALICO_CONFIG ./tools/gate/deploy-k8s.sh
else
	./tools/gate/deploy-k8s.sh
fi

## DEPLOY SCRIPTS
./tools/deployment/common/install-packages.sh

# Tweak openstack-helm/tools/deployment/common/wait-for-pods.sh to continue after "Some jobs have not succeeded" msg
# Remove "exit -1" from file, so the program can continue to install additional services
sed -i -e 's/exit -1/break/' $HOME/openstack-helm/tools/deployment/common/wait-for-pods.sh

apt install python3-dev --yes
./tools/deployment/common/setup-client.sh
./tools/deployment/component/common/ingress.sh
RUN_HELM_TESTS=$HELM_TESTS ./tools/deployment/component/common/openstack.sh

# Run test to validate config upgrade
if [ "$VALIDATE_UMBRELLA_CONFIG" == "true" ];then
./tools/gate/tests/validate-umbrella-upgrade-config-changes-do-not-update-other-components.sh
fi	

# Test creation of heat stacks
[ "$CREATE_STACK" == "yes" ] && ./tools/deployment/developer/common/900-use-it.sh


if [ "$INSTALL_HORIZON" == "true" ];then
	# Steps to access horizon WebUI
	HORIZON_INT_SVC_IP=$(kubectl -n openstack describe service horizon-int|awk '/^IP:/{print $2}')
	[ -z $HORIZON_INT_SVC_IP ] && echo "Error! Failed to install horizon" && exit 1
	
	echo "--------------------------------------------"
	echo "HORIZON IP: $HORIZON_INT_SVC_IP"
	echo
	echo "--> Add route in desktop to access horizon webUI:"
	echo
	echo "Linux Example: ip route add ${HORIZON_INT_SVC_IP} via <Openstack_Host_IP>"
	echo "Windows Example: route add ${HORIZON_INT_SVC_IP} via <Openstack_Host_IP>"
fi

