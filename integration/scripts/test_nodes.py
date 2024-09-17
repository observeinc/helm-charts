#!/usr/bin/env python3

import pytest
import base64
import json, yaml
import re




@pytest.mark.tags(
        "node_affinity.yaml")
def test_node_affinity(kube_client, helm_config):
    """
    This test does the following:
    - Check that the pod 'cluster-events' is scheduled on a node with label 'node-type=useme' using affinity

    *Note*:
    -  Because we use "requiredDuringSchedulingIgnoredDuringExecution", the pod MUST be scheduled onto the node with label
    -  See https://yuminlee2.medium.com/kubernetes-node-selector-and-node-affinity-ecb3a4d69165
    """

    key="node-type"
    operator="In"
    value="useme"
    label_selector = "app.kubernetes.io/name=cluster-events"

    print(f"Checking node affinity for pod containing '{label_selector}' ")

    #Get the pod with label 'app.kubernetes.io/name=cluster-events'
    pod = kube_client.list_namespaced_pod(namespace=helm_config['namespace'], label_selector=label_selector)
    assert pod.items, f"No pods found with label {label_selector} in namespace {helm_config['namespace']}"
    assert len(pod.items) == 1, f"Expected 1 pod with label {label_selector}, but found {len(pod.items)}"
    print(f"Found 1 pod with label {label_selector}")

    pod = pod.items[0] #There should only be one cluster-events pod

     # Assert that the pod has the specific affinity
    assert pytest.helpers.has_affinity(pod, key, operator, value), \
     f"Pod: {pod.metadata.name}, Namespace: {pod.metadata.namespace} does not have the expected affinity {key}={value}:{operator}"
    print(f"Pod {pod.metadata.name} has the expected affinity '{key}={value}:{operator}'")


    node_name = pod.spec.node_name
    node = kube_client.read_node(name=node_name) #Get the node name where the pod is scheduled on

    # Check the node where the pod is scheduled on to have the affinity desired

    assert node.metadata.labels.get("node-type") == "useme", \
        (f"Pod {pod.metadata.name} is not scheduled on a node {node.metadata.name }with label 'node-type=useme'")
    print(f"Pod {pod.metadata.name} is correctly scheduled on a node {node.metadata.name} with label 'node-type=useme'")


@pytest.mark.tags(
        "node_taint.yaml")
def test_node_taint(kube_client, helm_config):

    """
    This test does the following:
    - Check that the pod with defined toleration has the expected toleration
    - Check that the tainted node only containts the tolerated pod or none at all

    *Note*:
    Tolerations allow the scheduler to schedule pods with matching taints.
    Tolerations allow scheduling but DON'T GUARANTEE scheduling.
    See https://yuminlee2.medium.com/kubernetes-node-selector-and-node-affinity-ecb3a4d69165

    """

    toleration_key = "deployObserve"
    toleration_value = "notAllowed"
    toleration_effect = 'NoSchedule'
    label_selector = "app.kubernetes.io/name=cluster-events"

    print(f"Checking node taints for pod containing '{label_selector}'")

    #Get the pod with label 'app.kubernetes.io/name=cluster-events'
    pods = kube_client.list_namespaced_pod(namespace=helm_config['namespace'], label_selector=label_selector)
    assert pods.items, f"No pods found with label {label_selector} in namespace {helm_config['namespace']}"
    assert len(pods.items) == 1, f"Expected 1 pod with label {label_selector}, but found {len(pods.items)}"
    print(f"Found 1 pod with label {label_selector}")

    pod = pods.items[0] #There should only be one cluster-events pod

    # Assert that the pod has the specific toleration
    assert pytest.helpers.has_toleration(pod, toleration_key, toleration_value, toleration_effect), \
     f"Pod: {pod.metadata.name}, Namespace: {pod.metadata.namespace} does not have the toleration {toleration_key}={toleration_value}:{toleration_effect}"
    print(f"Pod {pod.metadata.name} has the expected toleration {toleration_key}={toleration_value}:{toleration_effect}")


    #Find the node with taint
    nodes = kube_client.list_node()
    for node in nodes.items:
        if(pytest.helpers.has_taint(node, toleration_key, toleration_value, toleration_effect)):
            tainted_node=node
            tainted_node_name = tainted_node.metadata.name

    #Ensure no other pods on this node are scheduled except *possibly* one we had selected with toleration
    pods = kube_client.list_namespaced_pod(namespace=helm_config['namespace'])
    pods_on_node = [
        pod for pod in pods.items
        if pod.spec.node_name == tainted_node_name #Filter by node name
    ]
    assert len(pods_on_node) <= 1, f"Expected at most 1 pod on node {tainted_node_name} in namespace {helm_config['namespace']}, but found {len(pods_on_node)}."
    if len(pods_on_node) == 1:
    # If a pod is found, ensure it is the expected pod
        assert pods_on_node[0].metadata.name == pod.metadata.name, \
            f"Expected pod {pod.metadata.name} on node '{tainted_node_name}', but found {pods_on_node[0].metadata.name}."
        print(f"Pod {pod.metadata.name} was correctly scheduled on Node '{tainted_node_name}'")
        print(f"No other pods were scheduled on tainted node '{tainted_node_name}")
    else:
        print(f"No pods were scheduled on tainted node '{tainted_node_name}' in namespace {helm_config['namespace']} as expected")
