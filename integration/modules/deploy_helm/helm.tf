# resource "kubernetes_namespace" "helm_namespace" {
#   metadata {
#     name = var.helm_chart_agent_test_namespace
#   }
# }

resource "helm_release" "observe-agent" {
  name      = var.helm_chart_agent_test_release_name
  chart     = "${path.module}/../../../charts/agent"
  #namespace = kubernetes_namespace.helm_namespace.metadata[0].name
  namespace = var.helm_chart_agent_test_namespace

  #atomic            = true
  #cleanup_on_fail   = true
  create_namespace  = true #Handled by k8s resource 
  dependency_update = true
  timeout           = 180 #k8s timeout

   values = [
    templatefile("${path.module}/values/${var.values_file}",
      {
        observe_url      = var.observe_url,
        observe_token = var.observe_token,
        helm_chart_agent_test_namespace = var.helm_chart_agent_test_namespace
      })
  ]
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