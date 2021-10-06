#------- Cluster
resource "aws_iam_role" "eks" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "eks.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks.name
}

#------- Workers
resource "aws_iam_role" "workers" {
  name = "eks-workers-role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : ["ec2.amazonaws.com"]
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.workers.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.workers.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.workers.name
}


#----- IAM role for service account
locals {
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
}

module "iam_assumable_role_aws_lb" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.6.0"

  aws_account_id = var.account_id
  create_role    = true
  role_name      = "AWSLoadBalancerControllerIAMRole"
  provider_url   = replace(aws_eks_cluster.test.identity[0].oidc[0].issuer, "https://", "")
  role_policy_arns = [
    "arn:aws:iam::${var.account_id}:policy/AWSLoadBalancerControllerIAMPolicy",
    "arn:aws:iam::${var.account_id}:policy/AWSLoadBalancerControllerAdditionalIAMPolicy"
  ]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.namespace}:${local.service_account}"]

  tags = {
    Terraform = "true"
  }
}
