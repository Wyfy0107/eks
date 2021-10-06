output "cluster_ca_cert" {
  value = aws_eks_cluster.test.certificate_authority
}

output "cluster_endpoint" {
  value = aws_eks_cluster.test.endpoint
}
