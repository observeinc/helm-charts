#!/usr/bin/env python3

from kubernetes import client
from .benchmark.k8s_metrics import get_pod_stats, parse_cpu_output, parse_memory_output
from .benchmark import (
    cluster_event_generator,
    log_generator,
    trace_generator,
    metrics_generator,
)
from .benchmark.volume_level import VolumeLevel
import pytest
import time
import sys
from typing import Dict, List


def get_csv_header(pod_names: List[str]):
    """
    Returns a csv header for the given pod names. The columns will be a single timestamp column,
    followed by a cpu and ram column for each pod.
    """
    return "ts," + ",".join(
        pod + suffix for pod in pod_names for suffix in ["_cpu", "_ram"]
    )


def get_perf_csv_row(
    custom_objects_api: client.CustomObjectsApi, namespace: str, pod_names: List[str]
):
    """
    This creates a row of observed perf data to add to our CSV. The first column is the timestamp,
    followed by a cpu and ram column for each pod.
    """
    by_pod = get_pod_stats(custom_objects_api, namespace)
    current_time = time.time_ns()
    columns = [current_time]
    for pod_name in pod_names:
        containers = by_pod.get(pod_name, [])
        if len(containers) != 1:
            print(
                f"Warning: expected 1 container for pod {pod_name}, found {containers}",
                file=sys.stderr,
            )
            columns.append("")
            columns.append("")
        else:
            columns.append(parse_cpu_output(containers[0]["cpu"]))
            columns.append(parse_memory_output(containers[0]["memory"]))
    return ",".join([str(col) for col in columns])


def sleep_until(nanos: int):
    time.sleep(float(nanos - time.time_ns()) / 1e9)


@pytest.mark.skip(reason="remove this line to run the benchmark test")
@pytest.mark.tags("default.yaml", "node_affinity.yaml", "node_taint.yaml")
def test_benchmark(
    kube_client: client.CoreV1Api,
    kube_api_client: client.CustomObjectsApi,
    kube_custom_objects_api: client.CustomObjectsApi,
    kube_rbac_client: client.RbacAuthorizationV1Api,
    apps_client: client.AppsV1Api,
    helm_config: Dict[str, str],
):
    """_summary_
    This test creates various load generators and measures pod performance metrics.
    """

    # ================================================================================
    # Configure the test here
    # ================================================================================
    test_duration_seconds = 10 * 60
    setup_sleep_seconds = 4 * 60
    sample_offset_seconds = 5

    cluster_volume_level = VolumeLevel.LOW
    trace_volume_level = VolumeLevel.MEDIUM
    metrics_volume_level = VolumeLevel.LOW
    log_volume_level = VolumeLevel.LOW
    # ================================================================================
    # End of configurable section
    # ================================================================================

    # List all pods in the specified namespace
    ns = helm_config["namespace"]
    pods = kube_client.list_namespaced_pod(namespace=ns)
    agent_pods = [
        pod.metadata.name for pod in pods.items if "agent" in pod.metadata.name
    ]
    agent_pods = sorted(agent_pods)
    num_deployments = 3
    num_daemonsets = 2
    # The num nodes is computed assuming `num_pods = num_deployments + num_daemonsets * num_nodes`
    if len(agent_pods) < (num_deployments + num_daemonsets) or (len(agent_pods) - num_deployments) % num_daemonsets != 0:
        raise Exception(
            "Expected to have %d singleton agent deployments plus %d agent daemonsets, saw %d pods."
            % (num_deployments, num_daemonsets, len(agent_pods))
        )
    num_nodes = (len(agent_pods) - num_deployments) // num_daemonsets
    csv = get_csv_header(agent_pods)

    print(
        f"Starting generators with volume: cluster={cluster_volume_level.name}, trace={trace_volume_level.name}, metrics={metrics_volume_level.name}, log={log_volume_level.name}"
    )

    # Ensure this is long enough so the generators will run until we call stop.
    generator_duration_seconds = test_duration_seconds + setup_sleep_seconds + 120
    # Start the daemonsets first to help with pod scheduling
    print("Starting traces...")
    trace_generator.start_load_generation(
        apps_client, ns, num_nodes, trace_volume_level, generator_duration_seconds
    )
    print("Starting metrics...")
    metrics_generator.start_load_generation(
        apps_client, ns, num_nodes, metrics_volume_level, generator_duration_seconds
    )
    print("Starting logs...")
    log_generator.start_load_generation(
        apps_client, ns, num_nodes, log_volume_level, generator_duration_seconds
    )
    print("Starting cluster events...")
    cluster_event_generator.start_load_generation(
        kube_api_client, ns, cluster_volume_level
    )

    print("Sleeping while generators start up...")
    time.sleep(setup_sleep_seconds)
    print("Starting test...\n")
    print(csv)

    end_time = time.time_ns() + test_duration_seconds * 1e9
    while True:
        now = time.time_ns()
        if now > end_time:
            break
        row = get_perf_csv_row(kube_custom_objects_api, ns, agent_pods)
        print(row)
        csv += "\n" + row
        sleep_until(now + sample_offset_seconds * 1e9)

    cluster_event_generator.stop_load_generation(
        kube_client, kube_rbac_client, ns, cluster_volume_level
    )
    trace_generator.stop_load_generation(apps_client, ns)
    metrics_generator.stop_load_generation(apps_client, ns)
    log_generator.stop_load_generation(apps_client, ns)
    time.sleep(2)

    with open("agent_benchmark.csv", "w") as f:
        print("\n\nwriting results to agent_benchmark.csv")
        f.write(csv)
