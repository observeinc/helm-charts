#!/usr/bin/env python3

import pytest
from . import helpers as h


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
