#!/usr/bin/env python3

import pytest
import base64 
import json, yaml
import re


@pytest.mark.tags(
        "default.yaml",
        "non-default.yaml")
def test_errors_logs(kube_client, helm_config):
     # List all pods in the specified namespace
    pods = kube_client.list_namespaced_pod(namespace=helm_config['namespace'])
    ignore_error_patterns = [
        "failed to retrieve ConfigMap kube-system/aws-auth" 
    ]
    expected_good_logs = ["Starting observe-agent"] #Check observe-agent starts in every pod 

    # Iterate through each pod and retrieve the logs
    for pod in pods.items:
        pod_name = pod.metadata.name
        print(f"\nChecking Errors in Pod: {pod_name}")   
        try:
            # Get logs for the pod           
            pod_logs = kube_client.read_namespaced_pod_log(name=pod_name, namespace=helm_config['namespace'])
             # Check for expected logs
            for pattern in expected_good_logs:
                if pattern in pod_logs:
                    print(f"Found expected log '{pattern}' in logs of pod {pod_name}")
                else:
                    pytest.fail(f"Expected log '{pattern}' not found in logs of pod {pod_name}: {pod_logs}")

            # Parse the logs for any known error patterns or warning messages
            if "error" in pod_logs.lower() or "failed" in pod_logs.lower():
                for pattern in ignore_error_patterns:
                    if pattern in pod_logs:
                        print(f"Ignoring expected error '{pattern}' in logs of pod {pod_name}")
                        #continue
                    else:
                        pytest.fail(f"Generic error found in logs of pod {pod_name}: {pod_logs}")       
           
        except pytest.helpers.ApiException() as e:
            pytest.fail(f"Could not retrieve logs for pod {pod_name}: {e}")
        
    
