# Krich Group Openstack Autoscaling Dask Cluster

## TODO
 
 - Scratch disks

This is a collection of heat templates, scripts, and Ansible playbooks to deploy a Dask cluster on the Arbutus Openstack environment.

## Prerequisites

### Installing and Setting Up Ansible

Do all this from the root of the repo to set up your machine for running all the Ansible playbooks in this repo.

- Install pipx: `python3 -m pip install --user pipx`
- Install Ansible and extra dependencies: `pipx install ansible --include-deps && pipx inject ansible openstacksdk`
- Install openstack Ansible collection: `ansible-galaxy collection install openstack.cloud`
- Install openstack client: `pipx install --include-deps openstackclient`
- Create the private directory for storing secrets: `mkdir private`
- Create the vault password file within the private directory and populate it with the password for decrypting secrets: `echo "ask kyle for this string" > private/vault_password`

### Configuring Openstack

You'll need to configure your local Openstack tools with credentials in order to deploy the Openstack Heat "stack" (domain-specific lingo there) that provisions the infrastructure for the cluster. This is done by adding the following to your `~/.config/openstack/clouds.yaml` file:

```{.yaml}
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

After you've added the above to your `clouds.yaml` file, you need to set an environment variable specifying which cloud environment you'd like to work on. Do that with

```
export OS_CLOUD=def-jkrich-arbutus
```

Then test it out with a simple command like

```:
openstack image list
```

## Deploying the Cluster

We use Ansible as the orchestration engine that does the following things:

  - Provisions all the infrastructure using the Openstack Heat infrastructure templates in `files/heat/`
  - Sets up a local SSH config file for connecting to all the nodes in the cluster via the login node in `files/ssh.cfg`
  - Installs all the software on the cluster nodes for running Dask and Simudo

To see the tasks that will be run by Ansible, execute the following command:

```
ansible-playbook -i inventory --vault-password-file private/vault_password -v site.yml --list-tasks
```

To deploy the entire cluster from scratch, run the following command:

```
ansible-playbook -i inventory --vault-password-file private/vault_password site.yml
```

This will create a relatively small cluster by default. To create a larger cluster, you can specify the minimum number of compute nodes to create by editing the `min_cluster_size` variable in the `files/heat/env.yaml` file. The `files/heat/env.yaml` file contains all the configurable parameters for deploying the cluster infrastructure. You can also scale the number of compute nodes in an existing cluster up and down automatically after it's been created (see below).

## Scaling the cluster

There are two convenience scripts in place at the root of the repo that automatically scale the cluster up and down. These scripts are just wrappers around the `openstack stack resource signal` command. To scale up, run:

```
./scale_up.sh
```

And to scale down:

```
./scale_down.sh
```

These scripts will scale the cluster up and down one machine at a time. To scale up/down by more than one machine at a time, just run the either of the commands in a small loop:

```
for i in $(seq 1 ${NUMBER_OF_NODES_TO_ADD}); do ./scale_up.sh; done
``` 

or

```
for i in $(seq 1 ${NUMBER_OF_NODES_TO_REMOVE}); do ./scale_down.sh; done
``` 

## Testing the cluster

To test the cluster, first create a Python virtual environment for all our dependencies. Feel free to use your tool of choice for creating virtual environments, but here is an example command:

```
virtualenv ./venv
```

Then activate it:

```
source ./venv/bin/activate
```

Then install all our dask dependencies:

```
pip install "dask[complete]"
```

Next, use SSH tunneling to tunnel the important Dask services to your local machine:

```
ssh -F files/ssh.cfg -f -N -L 8786:localhost:8786 headnode
ssh -F files/ssh.cfg -f -N -L 8787:localhost:8787 headnode
```

Open http://localhost:8787 in your browser to see the Dask dashboard, which you can use to monitor the cluster and visualize your running jobs.

At last, you can run a test script that runs a small parameter sweep of Simudo simulations as the `ubuntu` user on the Dask cluster with the following command:

```
python3 test_dask.py
```

Keep an eye on the dashboarx to see the jobs running on the cluster, their status (failure, success, etc), and stats about their runtime and resource consumption. You should also see some useful terminal output indicating what the script is doing. 

When the script completes, SSH into the login node by running 

```
ssh -F files/ssh.cfg headnode
```

from the root of the repo. See if the data made it over to the fileshare:

```

ls /share/ubuntu
```

## Configuration of the Cluster

There is a shared filesystem mounted at `/share` on all the nodes in the cluster. Every user should have their own directory at `/share/${username}` underneath the mountpoint. This is where you should put all your data, input files, code, etc. that you want to run on the cluster. This filesystem is backed by a CephFS filesystem, which is a distributed filesystem that is highly available and fault tolerant. It is also less performant than a locally attached disk, so you should only use it for data that you need to share between nodes in the cluster. For data that requires low latency access, a local disk is mounted at `/scratch` on each node for temporary storage.

## Useful Commands

### Tunnel Dask Cluster to your local machine

Tunnel the Dask scheduler to your local machine:

```
ssh -F files/ssh.cfg -N -L 8786:localhost:8786 headnode
```

Tunnel Dask dashboard to your local machine:

```
ssh -F files/ssh.cfg -N -L 8787:localhost:8787 headnode
```

Now go to localhost:8787 in your browser to see the Dask dashboard.

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
