data "kubernetes_nodes" "kind_nodes" {}
# Refetch the node details after taints and labels are applied
data "kubernetes_nodes" "kind_nodes_after" {
  depends_on = [kubernetes_labels.last_node_name, kubernetes_node_taint.last_node_name]
}
locals {
  node_names = [for node in data.kubernetes_nodes.kind_nodes.nodes : node.metadata.0.name]
  last_node_name = element(local.node_names, length(local.node_names) - 1)
  use_node_affinity = var.helm_chart_agent_test_values_file == "node_affinity.yaml"
  use_node_taint = var.helm_chart_agent_test_values_file == "node_taint.yaml"

}
# Output the updated node details
output "node-details" {
  value = [
    for node in data.kubernetes_nodes.kind_nodes_after.nodes : {
      name        = node.metadata.0.name
      taints      = length(node.spec.0.taints) > 0 ? node.spec.0.taints : null
      labels      = length(node.metadata.0.labels) > 0 ? node.metadata.0.labels : null
    }
  ]
}

resource "kubernetes_labels" "last_node_name" {

  count = local.use_node_affinity ? 1 : 0 #Label the last node for affinity testing
  api_version = "v1"
  kind        = "Node"
  metadata {
    name = local.last_node_name
  }
  labels = {
    "node-type" = "useme"
  }
}


resource "kubernetes_node_taint" "last_node_name" {
  count = local.use_node_taint ? 1 : 0 #Taint the last node for taint testing
  metadata {
    name = local.last_node_name
  }
  taint {
    key    = "deployObserve"
    value  = "notAllowed"
    effect = "NoSchedule"
  }
  force = true

}
