#!/bin/bash

stack_name="$1"
openrc="$2"
if [ -z "$stack_name" ]; then
    echo "Need to provide stack name as argument"
    exit 1
fi
if [ -z "$openrc" ]; then
    echo "Need to provide path to Openstack RC file as 2nd argument"
    exit 1
fi
echo "Sourcing Openstack RC file ..."
source "$openrc"
# Use openstack Heat CLI to deploy cluster and wait for creation to complete
echo "Beginning cluster creation ..."
openstack stack create -e heat/env.yaml -t heat/cluster.yaml --wait $stack_name
# Get public IP of the headnode
public_ip=`openstack stack output show -f shell $stack_name access_ip | grep output_value | cut -d'=' -f 2 | tr -d '"'`
echo "Headnode public ip: $public_ip"
# Replace it in the ssh.cfg used for setting up jumphost + multiplexing
sed "s/PUBLIC_IP/$public_ip/" ssh.template > ssh.cfg
# Wait for headnode to come up
echo "Waiting for $public_ip to come up"
ping -c 1 $public_ip
exitcode="$?"
while [ "$exitcode" != "0" ]; do
    echo "No response"
    ping -c 1 $public_ip > /dev/null
    exitcode="$?"
    sleep 5
done
echo "Host $public_ip up!"
internal_net=`grep 'internal_network' heat/env.yaml  | cut -d":" -f2 | tr -d "[:space:]"`
python openstack_inventory.py "$internal_net"
echo "Waiting for cloud init scripts to finish ..."
while [ -z "$(openstack console log show --lines 20 headnode | grep 'Cloud-init v.\+ finished')" ]; do
    sleep 5
done
echo "Cloud init complete! Running ansible playbooks ..."
ansible-playbook ./ansible/site.yml 
