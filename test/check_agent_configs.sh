#! /bin/bash

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <helm-export-file>"
  exit 1
fi

tmp_dir="/tmp/observe-agent-helm-check"
rm -rf $tmp_dir
mkdir $tmp_dir

# Relies on https://github.com/mikefarah/yq for yaml parsing
yq -e 'select(.kind == "ConfigMap" and .metadata.name == "observe-agent").data.relay' $1 > $tmp_dir/observe-agent.yaml

confs=$(yq -e 'select(.kind == "ConfigMap").metadata.name' $1 | grep -Ev 'cluster-name|observe-agent|---')
for conf in $confs; do
    yq -e "select(.kind == \"ConfigMap\" and .metadata.name == \"$conf\").data.relay" $1 > $tmp_dir/$conf.yaml

    # Remove any eks cloud detector since it errors outside of kubernetes
    yq -i '.processors.resourcedetection/cloud.detectors=["ec2"]' $tmp_dir/$conf.yaml

    # Remove root_path from hostmetrics since it errors outside of linux
    yq -i 'del(.receivers.hostmetrics.root_path)' $tmp_dir/$conf.yaml

    # Remove kubeletstats since it errors outside of kubernetes :(
    yq -i 'del(.receivers.kubeletstats*)' $tmp_dir/$conf.yaml
    yq -i '(.service.pipelines.*.receivers[] | select(. == "kubeletstats*")) |= "nop"' $tmp_dir/$conf.yaml

    # Remove loadbalancing exporter since it errors outside of kubernetes :(
    yq -i 'del(.exporters.loadbalancing*)' $tmp_dir/$conf.yaml
    yq -i '(.service.pipelines.*.exporters[] | select(. == "loadbalancing*")) |= "nop"' $tmp_dir/$conf.yaml

    echo "Checking $conf"
    # Set various env vars to match what's provided in our helm chart pod definitions.
    env MY_POD_IP=0.0.0.0 \
        GOMEMLIMIT=409MiB \
        OBSERVE_CLUSTER_NAME=observe-agent-monitored-cluster \
        OBSERVE_CLUSTER_UID=abc123 \
        K8S_NODE_NAME=test-node \
        KUBERNETES_SERVICE_HOST=0.0.0.0 \
        KUBERNETES_SERVICE_PORT=1234 \
        TOKEN=1234567890abcdefghij:1234567890abcdefghijklmnopqrstuv \
        TRACES_TOKEN=1234567890abcdefghij:1234567890abcdefghijklmnopqrstuv \
        observe-agent --config-mode=docker \
        --observe-config=$tmp_dir/observe-agent.yaml \
        --config=$tmp_dir/$conf.yaml config validate || true
    echo ""
done
