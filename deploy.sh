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
echo "Beginning cluster creation ..."
openstack stack create -e env.yaml -t cluster.yaml --wait $stack_name
public_ip=`openstack stack output show -f shell $stack_name access_ip | grep output_value | cut -d'=' -f 2 | tr -d '"'`
sed "s/PUBLIC_IP/$public_ip/" ssh.template > ssh.cfg
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
