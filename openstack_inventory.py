#!/usr/bin/env python
###############################################################################
# Dynamic inventory generation for Ansible
# Author lukas.pustina@codecentric.de
#
# This Python script generates a dynamic inventory based on OpenStack
# instances.
#
# The script is passed via -i <script name> to ansible-playbook. Ansible
# recognizes the execute bit of the file and executes the script. It then
# queries nova via the novaclient module and credentials passed via environment
# variables -- see below.
#
# The script iterates over all instances of the given tenant and checks if the
# instances' metadata have set keys OS_METADATA_KEY -- see below. These keys
# shall contain all Ansible host groups comma separated an instance shall be
# part of, e.g., u'ansible_host_groups': u'admin_v_infrastructure,apt_repos'.
# It is also possible to set Ansible host variables, e.g.,
# u'ansible_host_vars': u'dns_server_for_domains->domain1,domain2;key2->value2'
# Values with a comma will be transformed into a list.
#
# Metadata of an instance may be set during boot, e.g., > nova boot --meta
# <key=value> , or to a running instance, e.g., nova meta <instance name> set
# <key=value>
#
# *** Requirements *** * Python: novaclient module be installed which is part
# of the nova ubuntu package.  * The environment variables OS_USERNAME,
# OS_PASSWORD, OS_TENANT_NAME, OS_AUTH_URL must be set according to nova.
###############################################################################

from __future__ import print_function
from keystoneauth1 import session
from keystoneauth1.identity import v2
from novaclient import client as nclient
import copy
import os
import sys
import yaml


class NoAliasDumper(yaml.Dumper):
    def ignore_aliases(self, data):
        return True


OS_METADATA_KEY = {
    'host_groups': 'ansible_host_groups',
    'host_vars': 'ansible_host_vars'
}
# OS_NETWORK_NAME = 'igk-402_network'


def getOsCredentialsFromEnvironment():
    credentials = {}
    try:
        # credentials['VERSION'] = os.environ['OS_COMPUTE_API_VERSION']
        credentials['USERNAME'] = os.environ['OS_USERNAME']
        credentials['PASSWORD'] = os.environ['OS_PASSWORD']
        credentials['TENANT_NAME'] = os.environ['OS_TENANT_NAME']
        credentials['AUTH_URL'] = os.environ['OS_AUTH_URL']
    except KeyError as e:
        print("ERROR: environment variable %s is not defined" % e,
              file=sys.stderr)
        sys.exit(-1)

    return credentials


def main(args):
    if len(args) != 2:
        raise ValueError("Must pass in name of network as argument")
    OS_NETWORK_NAME = args[1]
    creds = getOsCredentialsFromEnvironment()
    auth = v2.Password(auth_url=creds['AUTH_URL'], username=creds['USERNAME'],
                       password=creds['PASSWORD'],
                       tenant_name=creds['TENANT_NAME'])
    sess = session.Session(auth=auth)
    nt = nclient.Client('2', session=sess)

    inventory = {'all':
                 {'hosts': {}, 'children': {}}
                 }
    # inventory['_meta'] = { 'hostvars': {} }
    for server in nt.servers.list():
        fixed_ip = get_fixed_ip(server,  OS_NETWORK_NAME)
        host_vars = get_host_vars(server)
        server_data = {fixed_ip: host_vars}
        if fixed_ip not in inventory['all']['hosts']:
            inventory['all']['hosts'].update(server_data)
        for group in map(str, get_groups(server)):
            if group not in inventory['all']['children']:
                children = inventory['all']['children']
                children[group] = {'hosts': copy.copy(server_data)}
            else:
                hosts = inventory['all']['children'][group]['hosts']
                hosts.update(copy.copy(server_data))
        # print()
        # print(yaml.dump(inventory, Dumper=NoAliasDumper))
        # print()
    with open('ansible_hosts.yaml', 'w') as fout:
        yml_txt = yaml.dump(inventory, Dumper=NoAliasDumper)
        print(yml_txt)
        fout.write(yml_txt)


def get_floating_ip(server, network):
    """
    Get floating IP of server on given network
    """

    for addr in server.addresses.get(network):
        if addr.get('OS-EXT-IPS:type') == 'floating':
            return str(addr['addr'])
    return None


def get_fixed_ip(server, network):
    """
    Get fixed IP of server on given network
    """

    for addr in server.addresses.get(network):
        if addr.get('OS-EXT-IPS:type') == 'fixed':
            return str(addr['addr'])
    return None


def get_groups(server):
    metadata = server.metadata.get('ansible_host_groups', None)
    if metadata:
        return metadata.split(',')
    else:
        return []


def get_host_vars(server):
    """
    Get the host_vars metadata from a server
    """

    metadata = server.metadata.get('ansible_host_vars', None)
    if metadata:
        host_vars = {}
        for kv in metadata.split(';'):
            key, values = kv.split('->')
            values = values.split(',')
            host_vars[key] = values
        return host_vars
    else:
        return {}

if __name__ == "__main__":
    main(sys.argv)

