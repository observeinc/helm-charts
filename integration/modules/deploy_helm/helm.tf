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
  upper = false
}


resource "helm_release" "observe-agent" {
  #name = "observe-agent"
  name       = "helm-chart-agent-test-${random_string.unique_id.result}"
  chart      = "${path.module}/../../../charts/agent"
  namespace = "helm-chart-agent-test-ns-${random_string.unique_id.result}"

  atomic = true
  cleanup_on_fail = true
  create_namespace = true
  dependency_update = true 
  timeout = 90 #k8s timeout

  set {
    name = "observe.collectionEndpoint"
    value = var.OBSERVE_URL
  }
  set {
    name = "observe.token"
    value = var.OBSERVE_TOKEN
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