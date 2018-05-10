#!/bin/bash

#####################################################################################################
# Script: headnode_config.sh
# Author: Kyle Robertson
# Date: September 18, 2015
# Company: Worlcom Exchange Inc.
# Description: A bash script run by cloud-init on the TORQUE headnode that configures the entire 
# TORQUE environment. 
#####################################################################################################

set -x
# Change passwords
echo "root:stackops" | chpasswd
echo "centos:stackops" | chpasswd
# Install necessary packages
yum -y install epel-release libtool openssl-devel libxml2-devel boost-devel gcc gcc-c++ git nmap 
yum -y install sshpass
# Get IP and hostname and add to /etc/hosts
IP="$(ifconfig eth0 | grep 'inet' | awk '{print $2;}' | head -1)"
HOSTNAME="$(hostname)"
echo "$IP $HOSTNAME" >> /etc/hosts 
# Install TORQUE from source
git clone https://github.com/adaptivecomputing/torque.git -b 5.1.1 torque_5.1.1
cd torque_5.1.1
./autogen.sh
./configure
make
make install_server install_clients
# Add all compute nodes to /etc/hosts
node_ips=$(nmap -sn 10.20.18.0/24 | awk '/Nmap scan/ {print $5}' | head -n -1)
hostnames=()
for node_ip in ${node_ips[@]}; do
    HOST=$(sshpass -p stackops ssh -o StrictHostKeyChecking=no root@$node_ip 'hostname')
    if [[ $HOST != "" ]];
    then
        echo "$node_ip $HOST" >> /etc/hosts 
        hostnames+=("$HOST")
    else
        echo "No hostname"
    fi
done
# Configure authorization service to initialize on startup
cp contrib/init.d/trqauthd /etc/init.d/
chkconfig --add trqauthd
echo /usr/local/lib > /etc/ld.so.conf.d/torque.conf
ldconfig
service trqauthd start
export PATH=/usr/local/bin/:/usr/local/sbin/:$PATH
# Configure pbs_server to initialize on startup. This deletes nodes file!!
cp contrib/init.d/pbs_server /etc/init.d/pbs_server
chkconfig --add pbs_server
service pbs_server restart
# Basic TORQUE setup
qterm
echo y | ./torque.setup root
# Build nodes file
for host in ${hostnames[@]}; do
    echo "$host" >> /var/spool/torque/server_priv/nodes
done
echo "headnode" >> /var/spool/torque/server_priv/nodes
# Install necessary daemons/packages on compute nodes and distribute /etc/hosts file
make packages
for host in ${hostnames[@]}; do
    sshpass -p stackops scp -o StrictHostKeyChecking=no /etc/hosts root@$host:/etc/hosts
    sshpass -p stackops scp -o StrictHostKeyChecking=no torque-package-mom-linux-x86_64.sh root@$host:/tmp/torque-package-mom-linux-x86_64.sh
    sshpass -p stackops scp -o StrictHostKeyChecking=no torque-package-clients-linux-x86_64.sh root@$host:/tmp/torque-package-clients-linux-x86_64.sh
    sshpass -p stackops scp -o StrictHostKeyChecking=no contrib/init.d/pbs_mom root@$host:/etc/init.d/pbs_mom
    sshpass -p stackops ssh -o StrictHostKeyChecking=no root@$host /tmp/torque-package-mom-linux-x86_64.sh --install
    sshpass -p stackops ssh -o StrictHostKeyChecking=no root@$host /tmp/torque-package-clients-linux-x86_64.sh --install
    sshpass -p stackops ssh -o StrictHostKeyChecking=no root@$host '
    chkconfig --add pbs_mom
    service pbs_mom start
    '
done
# Restart pbs_server
qterm
pbs_server
# Configure a basic queue 
qmgr -c "create queue batch queue_type=execution"
qmgr -c "set queue batch started=true"
qmgr -c "set queue batch enabled=true"
qmgr -c "set queue batch resources_default.nodes=1"
qmgr -c "set queue batch resources_default.walltime=3600"
qmgr -c "set server default_queue=batch"
## Restart pbs_mom daemons on compute nodes
#for host in ${hostnames[@]}; do
#    sshpass -p stackops ssh -o StrictHostKeyChecking=no root@$host service pbs_mom restart
#done

