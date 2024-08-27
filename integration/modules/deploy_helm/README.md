## deploy_helm
This module is responsbile for deploying the agent helm release to a K8s cluster. 

This module is used in integration tests (via `terraform test` ) to install and uninstall the local agent helm release 

## inputs

The modules takes in the following required variables:

- observe_url
  - URL for helm chart to send data
- observe_token  
  - Token for helm chart to send data



### provider 
The provider is set to use the `helm` and `kubernetes` providers. 

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


