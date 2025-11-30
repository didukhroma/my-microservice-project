resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }

  timeouts {
    delete = "30m"
  }
}

resource "kubernetes_namespace" "django_app" {
  metadata {
    name = "django-app"
  }
}

# 1. Встановлюємо сам Argo CD з офіційного чарта
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.51.6"

  timeout = 900
  wait    = true

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [kubernetes_namespace.argocd]
}

# 2. Ставимо наш локальний чарт, який створює ArgoCD Application'и
resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts"  # локальний чарт у modules/argo_cd/charts
  namespace = kubernetes_namespace.argocd.metadata[0].name

  values = [
    file("${path.module}/charts/values.yaml")
  ]

  depends_on = [
    helm_release.argocd
  ]
}
