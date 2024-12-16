#!/usr/bin/env python3

import pytest
import warnings

@pytest.mark.tags(
        "default.yaml",
        "node_affinity.yaml",
        "node_taint.yaml")
def test_errors_logs(kube_client, helm_config):

    """_summary_

    This test does the following:
    - Check that all pods in the cluster's namespace have no 'level': 'error' in their json logs
    - Check that all pods have the expected logs
    """

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

            for pattern in expected_good_logs:    # Check that some expected logs exist
                if pattern in pod_logs:
                    print(f"Found expected log '{pattern}' in logs of pod {pod_name}")
                else:
                    pytest.fail(f"Expected log '{pattern}' not found in logs of pod {pod_name}")

            parsed_logs=pytest.helpers.parseLogs(pod_logs) #Parse logs to json

            for entry in parsed_logs:
                if entry.get("level") == "error":  #Explicity check for {'level':'error', .....}
                    pytest.fail(f"Found error entry in logs of pod {pod_name}: {entry}")
                if entry.get("level") == "warn":  #Explicity check for {'level':'warn', .....}
                   warnings.warn(UserWarning(f"Found warning entry in logs of pod {pod_name}: {entry}"))

        except pytest.helpers.ApiException() as e:
            pytest.fail(f"Could not retrieve logs for pod {pod_name}: {e}")

        print(f"No 'level': 'error' found in logs of pod {pod_name}")
