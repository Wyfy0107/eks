#--------- Cluster
resource "aws_security_group" "cluster" {
  description = "EKS cluster security group."
  vpc_id      = aws_vpc.eks.id
}

resource "aws_security_group_rule" "cluster_egress_internet" {
  description = "Allow cluster egress access to the Internet."
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.cluster.id
  type              = "egress"
}

resource "aws_security_group_rule" "cluster_https_worker_ingress" {
  description = "Allow pods to communicate with the EKS cluster API."
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443

  source_security_group_id = aws_security_group.workers.id
  security_group_id        = aws_security_group.cluster.id
  type                     = "ingress"
}

#--------- Workers
resource "aws_security_group" "workers" {
  description = "Security group for all nodes in the cluster."
  vpc_id      = aws_vpc.eks.id

  tags = {
    # This tag is required when attaching multiple sgs
    "kubernetes.io/cluster/test-cluster" = "shared"
  }
}

resource "aws_security_group_rule" "workers_egress_internet" {
  description = "Allow nodes all egress to the Internet."
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 0
  to_port     = 0

  security_group_id = aws_security_group.workers.id
  type              = "egress"
}

resource "aws_security_group_rule" "workers_ingress_self" {
  description = "Allow node to communicate with each other."
  protocol    = "-1"
  self        = true
  from_port   = 0
  to_port     = 0

  security_group_id = aws_security_group.workers.id
  type              = "ingress"
}


resource "aws_security_group_rule" "workers_ingress_control_plane" {
  description = "Allow control plane to communicate with worker nodes"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0

  source_security_group_id = aws_security_group.cluster.id
  security_group_id        = aws_security_group.workers.id
  type                     = "ingress"
}

