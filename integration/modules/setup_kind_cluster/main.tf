resource "kind_cluster" "cluster" {
  name = "test-kind-cluster"
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

resource "kind_cluster" "cluster2" {
  name = "test-kind-cluster-2"
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