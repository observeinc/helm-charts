## Integration Tests


The root of this module location is intended to run integration tests using the terraform test framework. The tests are located at `integration/tests`

The tests are run using the `terraform test -verbose` command from this folder `helm-charts/integration`

When the above command is run, the tests in the `integration/tests` directory are ran using the variables provided. The tests are ran in the order of the run blocks provided in `<test>.tftest.hcl`

Generally a test will do the following
- Create a local kind K8s cluster (`modules/create_kind_cluster`)
- Install the `agent` helm chart in the cluster (`modules/deploy_helm`)
- Run a test using `observeinc/collection/aws//modules/testing/exec` module to accept python scripts located at `integration/tests/scripts` These scripts test the various flows of the helm chart installation


### Variables

The tests are run using the following variables. These can be set in the `integration/tests.auto.tfvars` file for local testing if needed.

The required variables which must be set manually (as they are sensitive) are:
```
observe_url  = "https://<TENANT_ID>.collect.<DOMAIN>.com"
observe_token = "your-secure-observe-token"
```

Note that the kubernetes and helm providers are automatically specified to use your `~/.kube/config` file by default, when using the context created by the kind cluster.


### Local sandboxing

To manually setup a kind cluster and install the helm chart WITHOUT running tests, refer to [local sandbox module](modules/local_sandbox/README.md)

After creation of cluster and helm-chart installation, any of the python scripts in `/scripts` directory can be tested by running them directly against the local kind cluster.