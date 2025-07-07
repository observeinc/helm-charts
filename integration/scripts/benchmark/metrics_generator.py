from kubernetes import client
from .volume_level import VolumeLevel
import math


METRICS_DAEMONSET_NAME = "otelgen-metrics"


def start_load_generation(
    apps_client: client.AppsV1Api,
    namespace: str,
    num_nodes: int,
    volume_level: VolumeLevel,
    duration_seconds: int,
):
    if volume_level == VolumeLevel.OFF:
        return
    daemonset = _make_otelgen_metrics_daemonset(
        namespace, METRICS_DAEMONSET_NAME, num_nodes, volume_level, duration_seconds
    )
    apps_client.create_namespaced_daemon_set(namespace, daemonset)


def stop_load_generation(apps_client: client.AppsV1Api, namespace: str):
    all_daemonsets = apps_client.list_namespaced_daemon_set(namespace)
    if METRICS_DAEMONSET_NAME in [ds.metadata.name for ds in all_daemonsets.items]:
        apps_client.delete_namespaced_daemon_set(METRICS_DAEMONSET_NAME, namespace)


def _make_otelgen_metrics_daemonset(
    namespace: str,
    daemonset_name: str,
    num_nodes: int,
    volume_level: VolumeLevel,
    duration_seconds: int,
):
    # Total cluster rate (DPS)
    cluster_rate = {
        VolumeLevel.LOW: 100,
        VolumeLevel.MEDIUM: 1_000,
        VolumeLevel.HIGH: 10_000,
        VolumeLevel.MAX: 10_000,
    }[volume_level]
    # Convert to per-node rate
    rate = math.ceil(cluster_rate / float(num_nodes))

    container = client.V1Container(
        image="observemattc/otelgen-test:latest",
        name="sum-metrics",
        command=[
            "/otelgen",
            "--rate",
            str(rate),
            "--duration",
            str(duration_seconds),
            "--otel-exporter-otlp-endpoint",
            f"observe-agent-forwarder.{namespace}.svc.cluster.local:4318",
            "--protocol",
            "http",
            "--insecure",
            "--log-level",
            "warn",
            "metrics",
            "sum",
        ],
    )
    pod_name = "otelgen-metrics-pod"
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
