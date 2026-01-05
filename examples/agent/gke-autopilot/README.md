# GKE Autopilot Configuration

This example provides a values file for deploying the Observe agent on Google Kubernetes Engine (GKE) Autopilot clusters.

## Overview

GKE Autopilot is a managed Kubernetes environment that imposes certain restrictions on workloads. This configuration addresses the following Autopilot-specific considerations:

- **Remove `observeinc.com/unschedulable` affinity rule** for all components
- **Disable host metrics collection** since the host is abstracted away in Autopilot
- **Remove unnecessary volume mounts** Since we are not collecting host metrics, we can remove the associated volume mounts

## Key Configuration Changes

### Volume Adjustments
The `node-logs-metrics` component uses only volume configurations that are compatible with Autopilot:
- Uses ConfigMap for observe-agent configuration
- Mounts `/var/log/pods` for log collection (supported hostPath in Autopilot)

## Usage

Deploy the Observe agent with GKE Autopilot configuration:

```bash
helm install observe-agent observe/agent \
  -n observe \
  --create-namespace \
  -f gke-autopilot-values.yaml \
  --set observe.token.value="YOUR_TOKEN" \
  --set observe.collectionEndpoint.value="YOUR_ENDPOINT"
```

Or upgrade an existing installation:

```bash
helm upgrade observe-agent observe/agent \
  -n observe \
  -f gke-autopilot-values.yaml \
  --set observe.token.value="YOUR_TOKEN" \
  --set observe.collectionEndpoint.value="YOUR_ENDPOINT"
```

## Customization

Update the `cluster.name` value to match your GKE Autopilot cluster name:

```yaml
cluster:
  name: your-gke-autopilot-cluster-name
```

## Additional Resources

- [GKE Autopilot Documentation](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
- [GKE Autopilot Workload Restrictions](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-security#workload-restrictions)
