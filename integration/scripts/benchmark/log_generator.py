from kubernetes import client
from .volume_level import VolumeLevel
import math


LOG_DAEMONSET_NAME = "log-generator"


def start_load_generation(
    apps_client: client.AppsV1Api,
    namespace: str,
    num_nodes: int,
    volume_level: VolumeLevel,
    duration_seconds: int,
):
    if volume_level == VolumeLevel.OFF:
        return
    daemonset = _make_loggenerator_daemonset(
        LOG_DAEMONSET_NAME, num_nodes, volume_level, duration_seconds
    )
    apps_client.create_namespaced_daemon_set(namespace, daemonset)


def stop_load_generation(apps_client: client.AppsV1Api, namespace: str):
    all_daemonsets = apps_client.list_namespaced_daemon_set(namespace)
    if LOG_DAEMONSET_NAME in [ds.metadata.name for ds in all_daemonsets.items]:
        apps_client.delete_namespaced_daemon_set(LOG_DAEMONSET_NAME, namespace)


def _make_loggenerator_daemonset(
    daemonset_name: str,
    num_nodes: int,
    volume_level: VolumeLevel,
    duration_seconds: int,
):
    # Rate is logs per minute, each log is just over 1KiB, these numbers will multiplied by 8
    # since the log generator creates 8 identical threads.
    LOGS_PER_SECOND_SCALAR = 7.5  # 60 seconds per minute / 8 threads

    # Total cluster rate
    cluster_rate = {
        VolumeLevel.LOW: math.ceil(100 * LOGS_PER_SECOND_SCALAR),
        VolumeLevel.MEDIUM: math.ceil(1_000 * LOGS_PER_SECOND_SCALAR),
        VolumeLevel.HIGH: math.ceil(10_000 * LOGS_PER_SECOND_SCALAR),
        VolumeLevel.MAX: math.ceil(10_000 * LOGS_PER_SECOND_SCALAR),
    }[volume_level]
    # Convert to per-node rate
    rate = math.ceil(cluster_rate / float(num_nodes))

    container = client.V1Container(
        image="observemattc/loggenerator:latest",
        name="loggenerator",
        command=[
            "/loggenerator",
            str(rate),
            str(math.ceil(duration_seconds / 60.0)),
        ],
    )
    pod_name = "loggenerator-pod"
    pod_template = client.V1PodTemplateSpec(
        spec=client.V1PodSpec(containers=[container]),
        metadata=client.V1ObjectMeta(name=pod_name, labels={"app": pod_name}),
    )
    daemonset = client.V1DaemonSet(
        api_version="apps/v1",
        kind="DaemonSet",
        metadata=client.V1ObjectMeta(name=daemonset_name),
        spec=client.V1DaemonSetSpec(
            template=pod_template,
            selector={"matchLabels": {"app": pod_name}},
        ),
    )
    return daemonset
