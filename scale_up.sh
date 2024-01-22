#!/bin/bash
set -euo pipefail
set -x


echo "Getting stack info ..."
stack_json="$(openstack stack resource list --format json -n 5 def-jkrich-dask-cluster-stack)"
scaleup_stack_name="$(echo "${stack_json}" | jq -r '.[] | select(.resource_type == "OS::Heat::ScalingPolicy" and (.resource_name | contains("scaleup")) ) | .stack_name')"
scaleup_policy_name="$(echo "${stack_json}" | jq -r '.[] | select(.resource_type == "OS::Heat::ScalingPolicy" and (.resource_name | contains("scaleup")) ) | .resource_name')"

echo "Signaling stack ${scaleup_stack_name} with policy ${scaleup_policy_name} ..."
openstack stack resource signal "${scaleup_stack_name}" "${scaleup_policy_name}"
echo Configuring additional nodes
ansible-playbook -i inventory --vault-password-file private/vault_password configure_nodes.yml
