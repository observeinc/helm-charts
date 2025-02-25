from kubernetes import client
import sys


def get_pod_stats(custom_objects_api: client.CustomObjectsApi, namespace: str):
    # Fetch metrics for all pods in all namespaces
    response = custom_objects_api.list_namespaced_custom_object(
        group="metrics.k8s.io", version="v1beta1", namespace=namespace, plural="pods"
    )
    by_pod = {
        item["metadata"]["name"]: [
            {
                "name": container["name"],
                "cpu": container["usage"]["cpu"],
                "memory": container["usage"]["memory"],
            }
            for container in item["containers"]
        ]
        for item in response["items"]
        if item["metadata"]["namespace"] == namespace
    }
    return by_pod


def parse_cpu_output(cpu_str: str) -> float:
    """
    Parse CPU output from kubernetes metrics. Returns CPU in cores.
    """
    if cpu_str[-1] == "n":
        # n means nano-cores
        return float(cpu_str[:-1]) / 1e9
    if cpu_str[-1] == "u":
        # u means micro-cores
        return float(cpu_str[:-1]) / 1e6
    if cpu_str[-1] == "m":
        # m means milli-cores
        return float(cpu_str[:-1]) / 1e3
    print(f"error: unknown cpu unit: {cpu_str}", file=sys.stderr)
    return -1


def parse_memory_output(mem_str: str) -> float:
    """
    Parse memory output from kubernetes metrics. Returns memory in Ki.
    """
    if mem_str[-2:] == "Ki":
        return float(mem_str[:-2])
    if mem_str[-2:] == "Mi":
        return float(mem_str[:-2]) * 1024
    if mem_str[-2:] == "Gi":
        return float(mem_str[:-2]) * 1024 * 1024
    print(f"error: unknown memory unit: {mem_str}", file=sys.stderr)
    return -1
