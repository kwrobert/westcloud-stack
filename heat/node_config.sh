#!/bin/bash

echo "Updating base packages ..."
apt update -y
apt upgrade -y
apt install -y python-pip python-dev python3 python3-pip python3-dev libsuitesparse-dev libfftw3-dev libopenblas-dev
pip install ansible python-openstackclient
echo "Updating /etc/hosts"
interface=$(ip addr show | awk '/inet.*brd/{print $NF}')
ip_addr=$(ip addr show $interface | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/')
echo "$ip_addr ""$(hostname)" >> /etc/hosts
echo "Cloning nanowire code ..."
mkdir -p /home/ubuntu/software
git clone https://github.com/kwrobert/nanowire.git /home/ubuntu/software/nanowire
cd /home/ubuntu/software/nanowire
git checkout develop
git submodule init
git submodule update
echo "Installing nanowire code dependencies ..."
pip3 install -r requirements.txt
echo "Making data dir"
mkdir /mnt/data
chown -R ubuntu:ubuntu /mnt/data
chown -R ubuntu:ubuntu /home/ubuntu/
