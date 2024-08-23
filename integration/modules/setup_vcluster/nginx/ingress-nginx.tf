data "aws_eks_cluster" "cluster" {
  name = "helm-charts-agent-eks"
}



resource "helm_release" "nginx_ingress" {
  name = "ingress-nginx"

  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.6.0"
  set {
    name  = "controller.extraArgs.enable-ssl-passthrough"
    value = ""
  }
}

