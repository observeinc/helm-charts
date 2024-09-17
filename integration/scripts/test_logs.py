#!/usr/bin/env python3

import pytest
import base64
import json, yaml
import re
import time


@pytest.mark.tags(
        "default.yaml",
        "node_affinity.yaml",
        "node_taint.yaml")
def test_errors_logs(kube_client, helm_config):

    """_summary_

    This test does the following:
    - Check that all pods in the cluster's namespace have no errors/warnings in their logs
    - Ignore expected errors
    - Check that all pods have the expected logs
    """


    ignore_error_patterns = [
        "failed to retrieve ConfigMap kube-system/aws-auth",
        "Exporting failed. Will retry the request after interval",
        "The resourceVersion for the provided watch is too old"
    ]
    expected_good_logs = [
        "Starting observe-agent"
    ]

    # List all pods in the specified namespace
    pods = kube_client.list_namespaced_pod(namespace=helm_config['namespace'])

    for pod in pods.items: #For each pod
        pod_name = pod.metadata.name
        print(f"\nChecking Logs in Pod: {pod_name}")
        try:
            pod_logs = kube_client.read_namespaced_pod_log(name=pod_name, namespace=helm_config['namespace'])
            pod_logs_lines=pod_logs.splitlines()[:250]  #Get the first 250 lines

            for pattern in expected_good_logs:    # Check that some expected logs exist
                if pattern in pod_logs:
                    print(f"Found expected log '{pattern}' in logs of pod {pod_name}")
                else:
                    pytest.fail(f"Expected log '{pattern}' not found in logs of pod {pod_name}")

            for line in pod_logs_lines:  #For each line in pod logs
                if "error" in line.lower() or "failed" in line.lower(): #Check for error or failed in log line
                    if any(pattern in line for pattern in ignore_error_patterns):
                        print(f"Ignoring expected error pattern log line: {line}") #Ignore expected errors
                    else:
                        pytest.fail(f"Generic error found in logs of pod {pod_name}: {line}")

        except pytest.helpers.ApiException() as e:
            pytest.fail(f"Could not retrieve logs for pod {pod_name}: {e}")
