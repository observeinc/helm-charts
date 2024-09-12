#!/usr/bin/env python3

import pytest
import base64 
import json, yaml
import re

@pytest.mark.tags("default.yaml", "observe")
def test_errors_logs(kube_client, helm_config):
     # List all pods in the specified namespace
    pods = kube_client.list_namespaced_pod(namespace=helm_config['namespace'])
    # Iterate through each pod and retrieve the logs
    for pod in pods.items:
        pod_name = pod.metadata.name
        print(f"Pod: {pod_name}")
        
        try:
            # Get logs for the pod           
            logs = kube_client.read_namespaced_pod_log(name=pod_name, namespace=helm_config['namespace'])
            print(logs)            

            #assert "error" not in logs.lower(), f"Error found in logs of pod {pod_name}"
        except pytest.helpers.ApiException() as e:
            pytest.fail(f"Could not retrieve logs for pod {pod_name}: {e}")
        
    
