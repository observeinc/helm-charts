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

    ignore_error_patterns = [
        # Sometimes the container operator of filelog doesn't understand the logs' format
        # This most likely happens when the log is corrupted or in a weird state
        # Let's prevent these errors from blocking integration tests.
        "failed to detect a valid container log format: entry cannot be parsed as container logs",
        # containerID is empty when a container is just created.
        "has an empty containerID",
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

            for entry in parsed_logs:  # Explicitly check for {'level': 'error', ...} for each log entry
                level = entry.get("level")
                if level == "error":
                    if (any(pattern in entry.get("msg") for pattern in ignore_error_patterns) or
                        any(pattern in entry.get("error") for pattern in ignore_error_patterns)):
                        print(f"Ignoring expected error pattern log in entry: {entry}")  # Ignore expected errors
                    else:
                        pytest.fail(f"Found error entry in logs of pod {pod_name}: {entry}")
                elif level == "warn":  # Explicitly check for {'level': 'warn', ...}
                    warnings.warn(UserWarning(f"Found warning entry in logs of pod {pod_name}: {entry}"))
                else:
                    continue

        except pytest.helpers.ApiException() as e:
            pytest.fail(f"Could not retrieve logs for pod {pod_name}: {e}")

        print(f"No 'level': 'error' found in logs of pod {pod_name}")
