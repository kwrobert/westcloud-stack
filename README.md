# Krich Group Openstack Autoscaling Dask Cluster

This is a collection of heat templates, scripts, and Ansible playbooks to deploy a Dask cluster on the Arbutus Openstack environment.

## Useful Commands

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
