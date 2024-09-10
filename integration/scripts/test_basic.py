#!/usr/bin/env python3

import pytest
import base64 
from . import helpers as h

@pytest.mark.tags("default.yaml", "observe")
def test_pods_state(kube_client, helm_config):
     # List all pods in the specified namespace
    pods = kube_client.list_namespaced_pod(namespace=helm_config['namespace'])

    all_running = True
    not_running_pods = []
    # Iterate over each pod and check its status
    for pod in pods.items:
        pod_name = pod.metadata.name
        pod_phase = pod.status.phase

        print(f"Checking Pod: {pod_name}, Phase: {pod_phase}")
        # Check if the pod is not in the 'Running' phase
        if pod_phase != 'Running':
            all_running = False
            not_running_pods.append((pod_name, pod_phase))

    # Assert that all pods are running
    assert all_running, f"Some pods are not running: {', '.join([f'{name} ({phase})' for name, phase in not_running_pods])}"
    print("All pods are running in the namespace:", helm_config['namespace'])


@pytest.mark.tags("default.yaml", "observe")
def test_config_map(kube_client, helm_config):

    #config_map = kube_client.read_namespaced_config_map(name="observe-agent",namespace=helm_config['namespace'])
    #print(config_map)

    expected_config_maps = {
        "daemonset-logs-metrics",
        "deployment-agent-monitor",
        "deployment-cluster-events",
        "deployment-cluster-metrics",
        "observe-agent",
        "cluster-name"
    } 

    config_maps=kube_client.list_namespaced_config_map(namespace=helm_config['namespace'])
    found_config_maps = set(config_map.metadata.name for config_map in config_maps.items)
    # Log and assert each expected ConfigMap is found
    for config_map_name in expected_config_maps:
        print(f"Checking ConfigMap: {config_map_name}")
        assert config_map_name in found_config_maps, f"ConfigMap {config_map_name} not found!"
    
    print("All expected ConfigMaps found.")


@pytest.mark.tags("default.yaml", "observe")
def test_secrets(kube_client, helm_config):
   

    # Checking the Secret "agent-credentials"
    secret_name = "agent-credentials"
    secret = kube_client.read_namespaced_secret(name=secret_name, namespace=helm_config['namespace'])

    # Decode the secret's value (secrets are Base64 encoded)
    secret_data = secret.data
    token_key = "OBSERVE_TOKEN"

    if token_key in secret_data:
        token_value = base64.b64decode(secret_data[token_key]).decode('utf-8')
        masked_token = token_value[:4] + "******" + token_value[-4:]  # Mask all but first 4 and last 4 chars
        print(f"Secret '{secret_name}' contains TOKEN (masked): {masked_token}")
        assert token_value, f"Secret '{secret_name}' has no value for TOKEN!"
    else:
        assert False, f"Secret '{secret_name}' does not contain OBSERVE_TOKEN!"

    print("Secret 'agent-credentials' with OBSERVE_TOKEN value verified.")