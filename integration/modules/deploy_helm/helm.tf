data "aws_eks_cluster" "cluster" {
  name = "helm-charts-agent-eks"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "helm-charts-agent-eks"
}
# Random String for naming
resource "random_string" "unique_id" {
  length  = 6
  special = false
  upper   = false
}

locals {
  helm_chart_agent_test_namespace = "helm-chart-agent-test-ns-${random_string.unique_id.result}"
  helm_chart_agent_test_name      = "helm-chart-agent-test-${random_string.unique_id.result}"
}

resource "helm_release" "observe-agent" {
  name      = local.helm_chart_agent_test_name
  chart     = "${path.module}/../../../charts/agent"
  namespace = local.helm_chart_agent_test_namespace

  atomic            = true
  cleanup_on_fail   = true
  create_namespace  = true
  dependency_update = true
  timeout           = 90 #k8s timeout

  set {
    name  = "observe.collectionEndpoint"
    value = var.OBSERVE_URL
  }
  set {
    name  = "observe.token"
    value = var.OBSERVE_TOKEN
  }
  set {
    name  = "namespaceOverride"
    value = local.helm_chart_agent_test_namespace
  }
  set {
    name  = "deployment-cluster-events.namespaceOverride"
    value = local.helm_chart_agent_test_namespace
  }
  set {
    name  = "deployment-cluster-metrics.namespaceOverride"
    value = local.helm_chart_agent_test_namespace
  }
  set {
    name  = "daemonset-logs-metrics.namespaceOverride"
    value = local.helm_chart_agent_test_namespace
  }

  # provisioner "local-exec" {
  #   command = "echo 'Deleting namespace ${self.metadata[0].namespace}' && kubectl delete namespace ${self.metadata[0].namespace}"
  #   when = destroy
  #   #on_failure = continue
  # }
}



# resource "null_resource" "post_destroy_command" {
#   # Force Terraform to run this resource after destroying a specific resource
#   triggers = {
#     always_run = "${timestamp()}" # This will ensure the null_resource runs each time
#   }
#   provisioner "local-exec" {
#     command = "echo 'Deleting namespace ${helm-release.observe-agent.metadata[0].namespace}' && kubectl delete namespace ${helm-release.observe-agent.metadata[0].namespace}"
#   }

#   # Ensure this runs after your main resource is destroyed
#   depends_on = [
#     helm-release.observe-agent_destroyed 
#   ]
# }






# resource "helm_release" "observe-stack-repo" {
#   name       = "observe-stack"
#   repository = "https://observeinc.github.io/helm-charts"
#   chart      = "stack"
#   create_namespace = true
#   dependency_update = true 
#   namespace = "observe"
#   timeout = 300 #This is default 
#   set {
#     name = "global.observe.collectionEndpoint"
#     value = var.OBSERVE_URL
#   }
#   set {
#     name = "observe.token.value"
#     value = var.OBSERVE_TOKEN
#   }
# }