import pytest
import os
from kubernetes import client, config


@pytest.fixture(scope="session", autouse=True)
def white_space():
    #print('\n')
    #print("-" * 60)
    yield
    #print('\n')
    #print("-" * 60)


@pytest.fixture(scope="function")
def kube_client():
    """
    Fixture to retrieve the Kubernetes client.

    Returns:
        client.CoreViApi()_: CoreV1Api client
    """
    # Load the kube config
    config.load_kube_config()
    contexts, active_context = config.list_kube_config_contexts()
    if not contexts:
        print("Cannot find any context in kube-config file.")
        return

    print("\n [kube_client] Active Context is {}".format(active_context['name']))
    v1 = client.CoreV1Api()
    return v1

@pytest.fixture(scope="function")
def apps_client():
    """
    Fixture to retrieve the Kubernetes client.

    Returns:
        client.AppsV1Api: AppsV1Api client
    """
    # Load the kube config
    config.load_kube_config()
    contexts, active_context = config.list_kube_config_contexts()
    if not contexts:
        print("Cannot find any context in kube-config file.")
        return

    print("\n [apps_client] Active Context is {}".format(active_context['name']))
    v1 = client.AppsV1Api()  # Use AppsV1Api to get deployments and daemonsets
    return v1

@pytest.fixture(scope="function")
def helm_config():
    """
    Fixture to retrieve the Helm namespace configuration.

    Returns:
        dict: Dictionary containing the Helm configuration.
    """

    # Get the HELM_NAMESPACE environment variable, defaulting to 'observe' if not set
    namespace = os.getenv('HELM_NAMESPACE', 'observe')
    # Create the Helm config dictionary
    config = {
        'namespace': namespace,
    }
    print(" [helm_config] - Helm config is: {}\n".format(config))
    return config


@pytest.helpers.register
def ApiException():
    """
    returns ApiException for k8s client 
    """    
    from kubernetes.client.rest import ApiException
    return ApiException

@pytest.helpers.register
def parseLogs():
    """
    returns 
    """
    return "Hi"