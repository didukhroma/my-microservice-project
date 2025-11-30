output "jenkins_url" {
  value       = "http://${try(data.kubernetes_service.jenkins.status[0].load_balancer[0].ingress[0].hostname, "pending")}:8080"
  description = "Jenkins LoadBalancer URL (може бути pending, поки LB ще створюється)"
}

output "jenkins_admin_user" {
  description = "Jenkins admin username"
  value       = var.jenkins_admin_user
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = var.jenkins_admin_password
  sensitive   = true
}

output "jenkins_namespace" {
  description = "Jenkins namespace"
  value       = var.namespace
}

data "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = var.namespace
  }
  
  depends_on = [helm_release.jenkins]
}