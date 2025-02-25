from kubernetes import client, utils
from .volume_level import VolumeLevel
import os
import tempfile
import time


def _get_namespaces(base_namespace: str, volume_level: VolumeLevel):
    num_ns = {
        VolumeLevel.OFF: 0,
        VolumeLevel.LOW: 1,
        VolumeLevel.MEDIUM: 10,
        VolumeLevel.HIGH: 20,
        VolumeLevel.MAX: 0,
    }[volume_level]
    return [f"{base_namespace}-otel-demo-{i+1}" for i in range(num_ns)]


def start_load_generation(
    api_client: client.ApiClient,
    namespace: str,
    volume_level: VolumeLevel,
):
    namespaces = _get_namespaces(namespace, volume_level)
    if len(namespaces) == 0:
        return
    current_dir = os.path.dirname(__file__)
    # First add the global objects a single time
    utils.create_from_yaml(
        api_client, os.path.join(current_dir, "otel-demo-cluster-role.yaml")
    )
    # Then add the namespace scoped objects once per namespace
    config = ""
    with open(os.path.join(current_dir, "otel-demo.yaml")) as f:
        config = f.read()
    # Use the grpc port
    config = config.replace(
        "__TRACE_ENDPOINT__",
        f"observe-agent-forwarder.{namespace}.svc.cluster.local:4317",
    )
    for demo_ns in namespaces:
        new_config = config.replace("__DEMO_NAMESPACE__", demo_ns)
        with tempfile.TemporaryDirectory() as tmpdir:
            file_path = os.path.join(tmpdir, "config.yaml")
            with open(file_path, "w") as f:
                f.write(new_config)
            utils.create_from_yaml(api_client, file_path, namespace=demo_ns)
            print(f"Created otel-demo in namespace {demo_ns}")
            time.sleep(10)


def stop_load_generation(
    kube_client: client.CoreV1Api,
    rbac_client: client.RbacAuthorizationV1Api,
    namespace: str,
    volume_level: VolumeLevel,
):
    namespaces = _get_namespaces(namespace, volume_level)
    if len(namespaces) == 0:
        return
    # Delete the cluster roles
    for role in ["grafana-clusterrole", "otel-collector", "prometheus"]:
        rbac_client.delete_cluster_role(role)
    # Then delete the namespaces to delete all ns scoped objects
    for demo_ns in namespaces:
        for role_binding in [
            "grafana-clusterrolebinding-{}",
            "otel-collector-{}",
            "prometheus-{}",
        ]:
            rbac_client.delete_cluster_role_binding(role_binding.format(demo_ns))
        kube_client.delete_namespace(demo_ns)
