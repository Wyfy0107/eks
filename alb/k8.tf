locals {
  cluster_name    = "test-cluster"
  service_account = "aws-load-balancer-controller"
}

resource "kubernetes_service_account" "aws_load_balancer_controller_service_account" {
  metadata {
    name      = local.service_account
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = data.aws_iam_role.irsa
    }
  }

  automount_service_account_token = true
}

resource "helm_release" "aws_load_balancer_controller_release" {
  name       = "aws-load-balancer-controller-release"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"


  set {
    name  = "clusterName"
    value = local.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = local.service_account
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = data.aws_iam_role.irsa
  }
}

resource "kubernetes_ingress" "aws_load_balancer_ingress" {
  metadata {
    name = "express-ingress"
    labels = {
      "app" = "express-server-ingress"
    }

    annotations = {
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/*"
          backend {
            service_name = kubernetes_service.express_service.metadata.0.name
            service_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "express_service" {
  metadata {
    name = "express-service"
  }

  spec {
    selector = {
      "app" = "express-server"
    }

    port {
      port        = 80
      target_port = 5000
    }

    type = "NodePort"
  }
}

resource "kubernetes_pod" "express" {
  metadata {
    name = "express-pod"
    labels = {
      app = "express-server"
    }
  }

  spec {
    container {
      image             = "wyfy/express-demo"
      name              = "express"
      image_pull_policy = "Always"

      port {
        container_port = 5000
      }
    }
  }
}
