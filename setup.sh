#!/bin/bash

distro='ubuntu1404'
version='8.0.61-1'
architecture=$(uname -m)

##
# install cuda driver on host machine
##
# pre
apt-get install linux-headers-$(uname -r)
# install 
wget http://developer.download.nvidia.com/compute/cuda/repos/${distro}/${architecture}/cuda-repo-${distro}_${version}_amd64.deb
dpkg -i cuda-repo-${distro}_${version}_amd64.deb
apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/${distro}/${architecture}/7fa2af80.pub
apt-get update
apt-get install -y cuda
# post
export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
/usr/bin/nvidia-persistenced --verbose
cat /proc/driver/nvidia/version

##
# install nvidia container runtime
##
# need to remove it and all existing GPU containers
docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f
apt-get purge -y nvidia-docker
# Add the package repositories
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  tee /etc/apt/sources.list.d/nvidia-docker.list
apt-get update
# Install nvidia-docker2 and reload the Docker daemon configuration
apt-get install -y nvidia-docker2
pkill -SIGHUP dockerd

