data "aws_eks_cluster" "cluster" {
  name = "helm-charts-agent-eks"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "helm-charts-agent-eks"
}

resource "helm_release" "observe-stack" {
  name       = "observe-stack"
  chart      = "${path.module}/../../../charts/stack"
  create_namespace = true
  namespace = "observe"
  dependency_update = true 
  timeout = 300 #This is default 
  set {
    name = "global.observe.collectionEndpoint"
    value = var.OBSERVE_URL
  }
  set {
    name = "observe.token.value"
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
#     value = "https://143958683374.collect.observe-staging.com/"
#   }
#   set {
#     name = "observe.token.value"
#     value = "ds13aZa5kaTPlP45ELKH:K3NIKVfTIJ94xh5DkFKCM9BNTgyRpXph"
#   }
# }