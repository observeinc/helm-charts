#!/usr/bin/env python3

import pytest
import base64 
import json, yaml
import re
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
    """
    This test does the following: 
    - Check that expected config maps exist in the cluster
    - Check that the 'observe-agent' config map 
       * Token value exists
       * Contains the correct token with correct structure 
    """

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
 

    # Check the 'observe-agent' ConfigMap for observe token
    print(f"Checking ConfigMap 'observe-agent' for token value")
    observe_agent_cm = next((cm for cm in config_maps.items if cm.metadata.name == "observe-agent"), None)
    relay_data = observe_agent_cm.data.get('relay', None) 
    assert relay_data, "ConfigMap 'observe-agent' does not contain relay data!"
    relay_data_dict = yaml.safe_load(relay_data) #Convert relay yaml to dict 

    token_key = "token"
    if token_key in relay_data_dict: #Check for existence of token + validate token key resolves to correct form  
        token_value = relay_data_dict["token"]

        assert token_value, f"ConfigMap 'observe-agent' has no value for token key {token_key}!"
        masked_token = token_value[:4] + "******" + token_value[-4:]  # Mask all but first 4 and last 4 chars
        
        pattern = r"^[a-zA-Z0-9]+:[a-zA-Z0-9]+$"
        assert re.match(pattern, token_value), f"ConfigMap 'observe-agent' has invalid value for token key {token_key}!"
        
        print(f"ConfigMap 'observe-agent' contains value for key '{token_key}' (masked): {masked_token}")
    else:
        assert False, f"ConfigMap 'observe-agent' does not contain token key '{token_key}'!"
    
    print("ConfigMap 'observe-agent' with token value verified.")

@pytest.mark.tags("default.yaml", "observe")
def test_secrets(kube_client, helm_config):
    """
    This test does the following: 
    - Check that expected secret `agent-credentials` exist in the cluster
    - Check that for the 'agent-credentials' secret 
       * Token value exists
       * Contains the correct token with correct structure
    """

    # Checking the Secret "agent-credentials" for observe token 
    print(f"Checking Secret 'agent-credentials' for OBSERVE_TOKEN value")
    secret_name = "agent-credentials"
    secret = kube_client.read_namespaced_secret(name=secret_name, namespace=helm_config['namespace'])

    # Decode the secret's value (secrets are Base64 encoded)
    secret_data = secret.data
    token_key = "OBSERVE_TOKEN"

    if token_key in secret_data: #Check for existence of token + validate token key resolves to correct form  
        token_value = base64.b64decode(secret_data[token_key]).decode('utf-8')

        assert token_value, f"Secret '{secret_name}' has no value for OBSERVE_TOKEN!"
        masked_token = token_value[:4] + "******" + token_value[-4:]  # Mask all but first 4 and last 4 chars

        pattern = r"^[a-zA-Z0-9]+:[a-zA-Z0-9]+$"
        assert re.match(pattern, token_value), f"Secret '{secret_name}' has invalid value for OBSERVE_TOKEN!"

        print(f"Secret '{secret_name}' contains OBSERVE_TOKEN (masked): {masked_token}")
    else:
        assert False, f"Secret '{secret_name}' does not contain OBSERVE_TOKEN!"

    print("Secret 'agent-credentials' with OBSERVE_TOKEN value verified.")