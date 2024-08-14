## deploy_helm
This module is responsbile for deploying the agent helm release to an EKS Cluster (`helm-charts-agent-eks`) in `nikhil-ps` member account in observe-blunderdome. The region is `us-west-2` 

This module is used in integration tests (via `terraform test` ) to install and uninstall the local agent helm release 

## inputs

The modules takes in the following required variables:
- cluster_role_arn 
  - Specify the iam role arn in `nikhil-ps` member account. Note this will be the arn for `gh-helm-charts-repo` as the role has specific IAM access to perform EKS tasks as well specifc access to the `helm-charts-agent-eks` EKS cluster via access policy
  - The kubernetes/helm provider will use this role to authenticate to the EKS cluster 
- OBSERVE_URL 
  - URL for helm chart to send data
- OBSERVE_TOKEN 
  - Token for helm chart to send data



### provider 
The provider is set to use the `helm` and `kubernetes` providers. The `kubernetes` provider is used to authenticate to the EKS cluster. The `helm` provider is used to deploy the agent helm release. 

Note: The authentication to EKS Cluster is done as an exec block. See terraform [docs](https://registry.terraform.io/providers/hashicorp/helm/latest/docs#exec-plugins)

If testing locally, create provider_override.tf with the following for local use, as the Github Actions flow uses OIDC. This will allow the aws, kubernetes, helm provider to all assume the role specified in the `cluster_role_arn` variable when authenticating (while still using the main blunderdome profile)

```
provider "aws" {
  region = var.region 
  profile = "blunderdome"
  assume_role {
    role_arn = var.cluster_role_arn
  }
}
```