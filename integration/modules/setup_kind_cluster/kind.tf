
resource "kind_cluster" "cluster" {
  name = var.kind_cluster_name
  kubeconfig_path = pathexpand(var.kind_cluster_config_path)
  node_image = "kindest/node:v1.31.0"
  wait_for_ready = true
  kind_config {
    kind = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }

    node {
      role = "worker"
    }

    node {
      role = "worker"
    }
  }
}

resource "null_resource" "wait_for_all_nodes" {
  triggers = {
    key = uuid()
  }

  provisioner "local-exec" {
    command = <<EOF
      printf "\nWaiting for all nodes to become ready...\n"
      kubectl wait --for=condition=Ready nodes --all --timeout=60s
      sleep 15
    EOF
  }

  depends_on = [kind_cluster.cluster]
}
