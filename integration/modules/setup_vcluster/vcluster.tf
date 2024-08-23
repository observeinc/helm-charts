# Random String for naming
resource "random_string" "unique_id" {
  length  = 6
  special = false
  upper   = false
}


# locals {
#   vcluster_name      = "${var.vcluster_prefix}-${random_string.unique_id.result}"
#   vcluster_namespace = "${var.vcluster_prefix}-${random_string.unique_id.result}"
# }

locals {
  vcluster_name      = "tf-vcluster"
  vcluster_namespace = "tf-vcluster"
}


data "aws_eks_cluster" "cluster" {
  name = "helm-charts-agent-eks"
}


resource "kubernetes_manifest" "ingress" {

  manifest = yamldecode(templatefile("manifests/ingresses/ingress.yaml", {
    vcluster_name      = local.vcluster_name,
    vcluster_namespace = local.vcluster_namespace
  }))
}
resource "helm_release" "my_vcluster" {
  depends_on = [
    kubernetes_manifest.ingress
  ]
  name             = local.vcluster_name
  namespace        = local.vcluster_namespace
  create_namespace = true

  repository = "https://charts.loft.sh"
  chart      = "vcluster"
  version    = "0.20.0"

  values = [
    templatefile("${path.module}/vcluster.yaml",
      {
        vcluster_name      = local.vcluster_name,
        vcluster_namespace = local.vcluster_namespace
    })
  ]
}

