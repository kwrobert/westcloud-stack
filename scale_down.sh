#!/bin/bash
set -euo pipefail
set -x


echo "Getting stack info ..."
stack_json="$(openstack stack resource list --format json -n 5 def-jkrich-dask-cluster-stack)"
scaledown_stack_name="$(echo $stack_json | jq -r '.[] | select(.resource_type == "OS::Heat::ScalingPolicy" and (.resource_name | contains("scaledown")) ) | .stack_name')"
scaledown_policy_name="$(echo $stack_json | jq -r '.[] | select(.resource_type == "OS::Heat::ScalingPolicy" and (.resource_name | contains("scaledown")) ) | .resource_name')"

echo "Scaling down stack $scaledown_stack_name with policy $scaledown_policy_name ..."
openstack stack resource signal $scaledown_stack_name $scaledown_policy_name
