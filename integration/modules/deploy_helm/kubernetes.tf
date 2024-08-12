data "aws_eks_cluster" "cluster" {
  name = "helm-charts-agent-eks"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "helm-charts-agent-eks"
}

resource "helm_release" "observe-stack" {
  depends_on = [ data.aws_eks_cluster.cluster, data.aws_eks_cluster_auth.cluster ]
  name       = "observe-stack"
  chart      = "${path.module}/../../../charts/stack"
  create_namespace = true
  namespace = "observe"


#   values = [
#     file("${path.module}/nginx-values.yaml")
#   ]
}