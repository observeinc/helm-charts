# Observe Helm Charts

This repository contains Helm charts for installing the telemetry agents required for Observe apps on Kubernetes. The current chart that should be used is `agent`. The other charts are deprecated and should not be used.

# Quick Start

First, install and update the observe helm repository:

```bash
helm repo add observe https://observeinc.github.io/helm-charts
helm repo update
```

## Namespace

We currently require that Observe charts are installed to an `observe` namespace.
The namespace should further be annotated with a human-readable cluster name. Helm
supports creating namespaces as a convenience feature, but does not support managing
and configuring the namespace (that is, the `--create-namespace` option in `helm install`
is equivalent to manually running `kubectl create namespace`). Thus it is recommended to
manage the namespace externally to Helm. This can likely be done by following the same
methodology you use to manage the creation of your Kubernetes clusters, and/or your other
namespaces.

You can also manage the namespace manually using the following commands:
```
kubectl create namespace observe
```

## Installing Agent stack
### Creating the token secret
The first step is to provision an Observe Ingest Token and create a secret in the `observe` namespace:
```
kubectl -n observe create secret generic agent-credentials --from-literal=OBSERVE_TOKEN=${YOUR_INGEST_TOKEN}

kubectl annotate secret agent-credentials -n observe \
  meta.helm.sh/release-name=observe-agent \
  meta.helm.sh/release-namespace=observe

kubectl label secret agent-credentials -n observe \
  app.kubernetes.io/managed-by=Helm
```

### Install stack
After the secret is created, you can install the agent stack.

```
helm install observe-agent observe/agent -n observe \
--set observe.collectionEndpoint.value="${OBSERVE_COLLECTION_ENDPOINT}" \
--set cluster.name="${CLUSTER_NAME}" \
--set cluster.deploymentEnvironment.name="${DEPLOYMENT_ENVIRONMENT_NAME}" \


# store values for further configuration and upgrades
helm -n observe get values observe-agent -o yaml > observe-agent-values.yaml
```

## Installing Traces
Traces and other app telemetry such as metrics can be sent to the `forwarder` daemonset that's installed as part of the `agent` stack. For more details please see the docs [here](https://docs.observeinc.com/en/latest/content/observe-agent/ConfigureApplicationInstrumentation.html)

## Sizing
For more details on default sizing and how to tune the services in the helm chart, please see the docs [here](https://docs.observeinc.com/en/latest/content/observe-agent/tune_services.html).

# Uninstall Stack
```helm -n observe uninstall observe-agent```

# Build

## Dependencies

Kind needs to be installed in order to build and test this repository:

https://kind.sigs.k8s.io/docs/user/quick-start/
