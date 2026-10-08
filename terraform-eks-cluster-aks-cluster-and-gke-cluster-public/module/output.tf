output "eks_cluster_name" {
  description = "AWS EKS Cluster Name"
  value       = aws_eks_cluster.eksdemo.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS Kubernetes API server"
  value       = aws_eks_cluster.eksdemo.endpoint
}

output "aks_cluster_name" {
  description = "Azure AKS Cluster Name"
  value       = azurerm_kubernetes_cluster.aks_cluster.name
}

output "aks_cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host
}

output "gke_cluster_name" {
  description = "Google GKE Cluster Name"
  value       = google_container_cluster.gke_cluster.name
}

output "gke_cluster_endpoint" {
  description = "IP address of the cluster master endpoint"
  value       = google_container_cluster.gke_cluster.endpoint
  sensitive   = true
}
