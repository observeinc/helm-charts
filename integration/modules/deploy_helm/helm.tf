
locals {
  helm_chart_agent_test_namespace = "helm-chart-agent-test-ns-${random_string.unique_id.result}"
  helm_chart_agent_test_release_name      = "helm-chart-agent-test-${random_string.unique_id.result}"
}



# Random String for naming
resource "random_string" "unique_id" {
  length  = 6
  special = false
  upper   = false
}

data "aws_eks_cluster" "cluster" {
  name = "helm-charts-agent-eks"
}

resource "kubernetes_namespace" "helm_namespace" {
  metadata {
    name = local.helm_chart_agent_test_namespace
  }
}

resource "helm_release" "observe-agent" {
  name      = local.helm_chart_agent_test_release_name
  chart     = "${path.module}/../../../charts/agent"
  namespace = kubernetes_namespace.helm_namespace.metadata[0].name

  atomic            = true
  cleanup_on_fail   = true
  create_namespace  = false #Handled by k8s resource 
  dependency_update = true
  timeout           = 120 #k8s timeout

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
  
}







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