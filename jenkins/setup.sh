#!/bin/bash

engine=podman
img_name=pjenkins
volume_name=jvol
container_name=jenkins

if ! which $container_engine > /dev/null 2>&1; then
  echo "$engine is not installed. Installing...."
  sudo dnf install $engine -y -q
fi
echo
echo "Starting image build..."
$engine build -t $img_name .

echo
echo "Creating $volume_name volume..."
$engine volume create $volume_name
echo
$engine volume inspect $volume_name

echo
echo "Starting $container_name container..."
if ! $engine ps |egrep -q $container_name;then
  $engine run -d --rm -p 8080:8080 -v $volume_name:/var/jenkins_home --name $container_name $img_name
fi

echo "Retrive admin password..."
$engine exec -it $container_name cat /var/jenkins_home/secrets/initialAdminPassword
