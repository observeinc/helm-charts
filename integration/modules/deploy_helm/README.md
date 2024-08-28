## deploy_helm
This module is responsbile for deploying the agent helm release to a K8s cluster. It is not intended to be called directly but instead from a root module with the correct provider configuration. See `modules/local_sandbox_kind` for an example of how to use this module.

This module is used in integration tests (via `terraform test` ) to install and uninstall the local agent helm release

## inputs

The modules takes in the following required variables:

- observe_url
  - URL for helm chart to send data
- observe_token
  - Token for helm chart to send data



### provider
The provider is set to use the `helm` and `kubernetes` providers.

If you already have a kube cluster configured would simply like to deploy a helm chart against it, simply do the following.

To run this module directly set the following in provider.tf:
```
provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}
```
