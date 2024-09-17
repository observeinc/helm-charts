import pytest
import os
import time
from kubernetes import client, config

def pytest_addoption(parser):
    parser.addoption("--slowdown", action="store", default=0.1, help="Delay between tests in seconds")

@pytest.hookimpl(tryfirst=True)
def pytest_runtest_protocol(item, nextitem):
    slowdown = float(item.config.getoption("--slowdown"))
    time.sleep(slowdown)  # Delay before each test


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
# Function to check if the node has the specific taint
def has_taint(node, key, value, effect):
    """
    Helper function checks if a node has key=value:effect taint applied on it

    Example taints:
    [{'effect': 'NoSchedule',
    'key': 'deployObserve',
    'time_added': None,
    'value': 'notAllowed'}]
    """

    taints = node.spec.taints
    if taints:
        for taint in taints:
            if (taint.key == key and
                (taint.value == value or value is None) and
                taint.effect == effect):
                return True
    return False

@pytest.helpers.register
#Function to check if a pod has the specific toleration
def has_toleration(pod, key, value, effect):

    """
    Helper function checks if a pod has key=value:effect toleration

    Example tolerations:
    [{'effect': 'NoSchedule',
        'key': 'deployObserve',
        'operator': 'Equal',
        'toleration_seconds': None,
        'value': 'notAllowed'}, {'effect': 'NoExecute',
        'key': 'node.kubernetes.io/unreachable',
        'operator': 'Exists',
        'toleration_seconds': 300,
        'value': None}]
    """

    tolerations = pod.spec.tolerations
    if tolerations:
        for toleration in tolerations:
            print("Pod Toleration is: {}".format(toleration))
            if (toleration.key == key and
                (toleration.value == value or value is None) and
                toleration.effect == effect):
                return True
    return False



@pytest.helpers.register
#Function to check if a pod has the specific affinity
def has_affinity(pod, key, operator, value):

    """
    Helper function checks if a pod has affinity
    """
    node_affinity = getattr(pod.spec.affinity, 'node_affinity', None)
    if node_affinity:
        terms = getattr(node_affinity.required_during_scheduling_ignored_during_execution, 'node_selector_terms', [])
        for term in terms:
            for expression in term.match_expressions:
                print("Pod Affinity expression is: {}".format(expression))
                if (expression.key == key and
                    expression.operator == operator and
                    (value in expression.values or value is None)):
                    return True
    return False
