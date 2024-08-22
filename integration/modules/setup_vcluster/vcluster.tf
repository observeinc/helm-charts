# Random String for naming
resource "random_string" "unique_id" {
  length  = 6
  special = false
  upper   = false
}


locals {
  vcluster_name      = "${var.vcluster_prefix}-${random_string.unique_id.result}"
  vcluster_namespace = "${var.vcluster_prefix}-${random_string.unique_id.result}"
}



data "aws_eks_cluster" "cluster" {
  name = "helm-charts-agent-eks"
}


resource "helm_release" "my_vcluster" {
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
  # provisioner "local-exec" {
  #   when = create 
  #   command = "nohup vcluster connect ${local.vcluster_name} --print > /tmp/vcluster.kubeconfig &"
  # }
}


