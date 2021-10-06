data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu-18_04" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

data "tls_certificate" "tls" {
  url = aws_eks_cluster.test.identity[0].oidc[0].issuer
}
