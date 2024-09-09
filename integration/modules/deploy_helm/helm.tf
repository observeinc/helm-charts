resource "helm_release" "observe-agent" {
  name       = var.helm_chart_agent_test_release_name
  namespace  = var.helm_chart_agent_test_namespace
  chart      = var.use_local_chart ? "${path.module}/../../../charts/agent" : "agent"
  repository = var.use_local_chart ? null : "https://observeinc.github.io/helm-charts"

  create_namespace  = true
  dependency_update = true
  timeout           = 120 #k8s timeout

  values = [
    templatefile("${path.module}/values/${var.helm_chart_agent_test_values_file}",
      {
        observe_url                     = var.observe_url,
        observe_token                   = var.observe_token,
        helm_chart_agent_test_namespace = var.helm_chart_agent_test_namespace
    })
  ]
}
