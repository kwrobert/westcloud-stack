#!/bin/bash

source admin_openrc.sh
export OS_IMAGE_API_VERSION=1

#glance image-create --copy-from http://cloud.centos.org/centos/6/images/CentOS-6-x86_64-GenericCloud-20141129_01.qcow2 --disk-format qcow2 --container-format bare --name 'CentOS 6' --is-public True
#
glance image-create --copy-from http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1503.qcow2 --disk-format qcow2 --container-format bare --name 'CentOS 7' --is-public True
#
#glance image-create --copy-from https://chef-server-glance-images.s3-us-west-2.amazonaws.com/chef-server-12.1.2-1437522600.qcow2 --disk-format qcow2 --container-format bare --name 'Chef Server' --is-public True
#
#glance image-create --copy-from http://cdimage.debian.org/cdimage/openstack/current/debian-8.2.0-openstack-amd64.qcow2 --disk-format qcow2 --container-format bare --name 'Debian Jessie 8.2.0 x64' --is-public True
#
#glance image-create --copy-from http://download.fedoraproject.org/pub/fedora/linux/releases/21/Cloud/Images/x86_64/Fedora-Cloud-Base-20141203-21.x86_64.qcow2 --disk-format qcow2 --container-format bare --name 'Fedora 21' --is-public True
#
#glance image-create --copy-from http://uec-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img --disk-format qcow2 --container-format bare --name 'Ubuntu Trusty 14' --is-public True


