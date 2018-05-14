#!/bin/bash

stack_name="$1"
openstack stack create -e env.yaml -t cluster.yaml --wait $stack_name
public_ip="$(openstack stack output show -f shell $stack_name access_ip | grep output_value | cut -d'=' -f 2 | tr -d '"')"
sed s/PUBLIC_IP/$public_ip/ ssh.template > ssh.cfg
 echo "Waiting for $public_ip to come up"
 ping -c 1 $public_ip
 while [ "$?" != "0" ]; do
     echo "No response"
     ping -c 1 $public_ip > /dev/null
     sleep 1
 done
 echo "Host $public_ip up!"
