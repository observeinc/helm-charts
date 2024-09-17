## Integration Tests


The root of this module location is intended to run integration tests using the terraform test framework. The tests are located at `integration/tests`

The tests are run using the `terraform test -verbose` command from this folder `helm-charts/integration`.  Before running this command, ensure that virtual enviroment is enabled:

```
integration git:(main) ✗ virtualenv venv source
integration git:(main) ✗ source scripts/venv/bin/activate
integration git:(main):✗ terraform test -verbose
```


When the above command is run, the tests in the `integration/tests` directory are ran using the variables provided. The tests are ran in the order of the run blocks provided in `<test>.tftest.hcl`

Generally a test will do the following
- Create a local kind K8s cluster (`modules/create_kind_cluster`)
- Configure the K8s cluster (`modules/setup_addnl_kubernetes`) if needed, based on the desired values file
- Install the `agent` helm chart in the cluster (`modules/deploy_helm`) with desired values file
- Run tests using `observeinc/collection/aws//modules/testing/exec` module to accept python scripts located at `integration/tests/scripts` These scripts test the various flows of the helm chart installation based on the values file.


### Variables

The tests are run using the following variables. These can be set in the `integration/tests.auto.tfvars` file for local testing if needed.


The **required** variables which must be set manually are:
```
observe_url  = "https://<TENANT_ID>.collect.<DOMAIN>.com"
observe_token = "your-secure-observe-token"
helm_chart_agent_test_values_file ="<xyz.yaml> #Generally this is default.yaml
```

Optionally, add below namespace variable if testing alternative namespace that's not called `observe`:
```
helm_chart_agent_test_namespace = "<some_other_namespace_to_test_helm_chart_installation>"
```
These variables get passed on to `modules/deploy_helm` and `modules/setup_addnl_kubernetes` appropriately when testing.

Note that the kubernetes and helm providers are automatically specified to use your `~/.kube/config` file by default, when using the context created by the kind cluster.


### Local sandboxing

To manually setup a kind cluster and install the helm chart WITHOUT running tests, refer to [local sandbox module](modules/local_sandbox/README.md)

After creation of cluster and helm-chart installation, any of the python scripts in `/scripts` directory can be tested by running them directly against the local kind cluster.

They can be called like the following example:.
```
export HELM_NAMESPACE=observe
(venv) ➜  integration git:(main) ✗ pytest ./scripts/test_logs.py -v -s --tags default.yaml
```
