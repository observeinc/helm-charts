# Purpose

This module is only intended to quickly install the agent helm chart without configuring a k8s cluster yourself and touching helm manually.  No tests will run here as this module just creates a kind cluster and installs a helm chart in it.


# Local Sandbox

Ensure you have the following installed:
    - Docker (https://docs.docker.com/get-docker/)
    - Terraform (https://learn.hashicorp.com/tutorials/terraform/install-cli)

If you want install kind cluster with defaults and then deploy helm chart locally through terraform, create a `terraform.auto.tfvars` file in this directory with the following content:

```
observe_url  = "https://your-observe-url.com"
observe_token = "your-secure-token"
```

Then run `terraform init` && `terraform apply` in this directory.

This will automatically create a local kind cluster and then install the `agent` helm chart in sequence using the defaults.

Note: Creation of the kind cluster will automatically change kube-context to refer to the kind cluster!
