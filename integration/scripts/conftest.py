import pytest

from kubernetes import client, config 

@pytest.fixture(scope="session")
def kube_client():
    # Load the kube config
    config.load_kube_config()

    # Return the CoreV1Api client
    v1 = client.CoreV1Api()
    return v1