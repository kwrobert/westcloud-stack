# Krich Group Openstack Autoscaling Dask Cluster

This is a collection of heat templates, scripts, and Ansible playbooks to deploy a Dask cluster on the Arbutus Openstack environment.

## Prerequisites

### Installing and Setting Up Ansible

Do all this from the root of the repo to set up your machine for running all the Ansible playbooks in this repo.

- Install Ansible and extra dependencies: `pipx install ansible --include-deps && pipx inject ansible openstacksdk`
- Install openstack Ansible collection: `ansible-galaxy collection install openstack.cloud`
- Install openstack client: `pipx install --include-deps openstackclient`
- Create the private directory for storing secrets: `mkdir private`
- Create the vault password file within the private directory: `echo "ask kyle for this string" > private/vault_password`

### Configuring Openstack

You'll need to configure your Openstack environment to allow the creation of autoscaling groups. This is done by adding the following to your `~/.config/openstack/clouds.yaml` file:

```
# This is a clouds.yaml file, which can be used by OpenStack tools as a source
# of configuration on how to connect to a cloud. If this is your only cloud,
# just put this file in ~/.config/openstack/clouds.yaml and tools like
# python-openstackclient will just work with no further config. (You will need
# to add your password to the auth section)
# If you have more than one cloud account, add the cloud entry to the clouds
# section of your existing file and you can refer to them by name with
# OS_CLOUD=def-jkrich-arbutus or --os-cloud=def-jkrich-arbutus
clouds:
  def-jkrich-arbutus:
    auth:
      auth_url: https://arbutus.cloud.computecanada.ca:5000
      username: "<your digital resource alliance username"
      password: "<your digital resource alliance password>"
      project_id: 62dc4b5bfd194371b1923426be14a856
      project_name: "def-jkrich"
      user_domain_name: "CCDB"
    region_name: "RegionOne"
    interface: "public"
    identity_api_version: 3
    # operation_log:
    #   logging: TRUE
    #   file: openstackclient_demo.log
    #   level: debug
    # log_file: /tmp/openstackclient_admin.log
    # log_level: debug
```


## Useful Commands

### Install all the openstack commands

```
pipx install --include-deps openstackclient
```

### Get list of available compute flavors

```
$ openstack flavor list -f json | jq -r '.[].Name'
c4-45gb-83
c2-15gb-31
c8-30gb-186
c4-30gb-83
c16-90gb-392
c2-7.5gb-31
c1-7.5gb-30
c8-90gb-186
c16-120gb-392
c8-60gb-186
c16-180gb-392
c4-15gb-83
c16-60gb-392
```

### Get list of available images

```
openstack image list -f json | jq -r '.[].Name'
```

### Scale up/down autoscaling group

Get resources in parent stack:

```
openstack stack resource list <parent stack name> -n 5
```

Find the child stack containing the scaling policies in the above list. Then scale up:

```
openstack stack resource signal <stack name> compute_cluster_scaleup_policy
```

Scale down:

```
openstack stack resource signal <stack name> compute_cluster_scaledown_policy
```
