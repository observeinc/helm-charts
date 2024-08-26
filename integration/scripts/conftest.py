import pytest

from kubernetes import client, config

@pytest.fixture(scope="session")
def kube_client():
    # Load the kube config
    config.load_kube_config()

    contexts, active_context = config.list_kube_config_contexts()
    if not contexts:
        print("Cannot find any context in kube-config file.")
        return

    print("Active Context is {}".format(active_context['name']))



    # Return the CoreV1Api client
    v1 = client.CoreV1Api()
    return v1