from kubernetes import client
from .volume_level import VolumeLevel
import math


TRACING_DAEMONSET_NAME = "otelgen-tracing"


def start_load_generation(
    apps_client: client.AppsV1Api,
    namespace: str,
    num_nodes: int,
    volume_level: VolumeLevel,
    duration_seconds: int,
):
    if volume_level == VolumeLevel.OFF:
        return
    daemonset = _make_otelgen_trace_daemonset(
        namespace, TRACING_DAEMONSET_NAME, num_nodes, volume_level, duration_seconds
    )
    apps_client.create_namespaced_daemon_set(namespace, daemonset)


def stop_load_generation(apps_client: client.AppsV1Api, namespace: str):
    all_daemonsets = apps_client.list_namespaced_daemon_set(namespace)
    if TRACING_DAEMONSET_NAME in [ds.metadata.name for ds in all_daemonsets.items]:
        apps_client.delete_namespaced_daemon_set(TRACING_DAEMONSET_NAME, namespace)


def _make_otelgen_trace_daemonset(
    namespace: str,
    daemonset_name: str,
    num_nodes: int,
    volume_level: VolumeLevel,
    duration_seconds: int,
):
    # Rate is traces per minute, each trace creates three spans.
    SPANS_PER_SECOND_SCALAR = 1.0 / 3.0

    # Total cluster rate
    cluster_rate = {
        VolumeLevel.LOW: math.ceil(100 * SPANS_PER_SECOND_SCALAR),
        VolumeLevel.MEDIUM: math.ceil(1_000 * SPANS_PER_SECOND_SCALAR),
        VolumeLevel.HIGH: math.ceil(10_000 * SPANS_PER_SECOND_SCALAR),
        VolumeLevel.MAX: math.ceil(10_000 * SPANS_PER_SECOND_SCALAR),
    }[volume_level]
    # Convert to per node rate
    rate = math.ceil(cluster_rate / float(num_nodes))

    container = client.V1Container(
        image="observemattc/otelgen-test:latest",
        name="basic-traces",
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
            "traces",
            "multi",
            "-s",
            "fast_basic",
        ],
    )
    pod_name = "otelgen-tracing-pod"
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
