output "azure_aks_eks_and_gke_details" {
  description = "Details of Azure AKS, AWS EKS and GCP GKE"
  value       = module.eks_cluster_aks_cluster_and_standard_gke_cluster 
  sensitive   = true
}
