resource "aws_eks_cluster" "test" {
  name     = "test-cluster"
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    endpoint_private_access = false
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.cluster.id]
    subnet_ids              = aws_subnet.public.*.id
  }

  kubernetes_network_config {
    service_ipv4_cidr = "10.100.0.0/16"
  }

  depends_on = [
    aws_iam_role.eks,
    aws_security_group.cluster
  ]
}

resource "aws_eks_node_group" "workers" {
  cluster_name           = aws_eks_cluster.test.name
  node_group_name_prefix = "eks-workers"
  node_role_arn          = aws_iam_role.workers.arn
  subnet_ids             = aws_subnet.public.*.id

  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  instance_types = ["t2.medium"]

  launch_template {
    name    = aws_launch_template.workers.name
    version = aws_launch_template.workers.latest_version
  }

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

resource "aws_launch_template" "workers" {
  name_prefix = "workers-launch-template"

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = [aws_security_group.workers.id]
  }

}

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.tls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.test.identity[0].oidc[0].issuer
}
