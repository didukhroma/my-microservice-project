output "eks_cluster_endpoint" {
  description = "EKS API endpoint for connecting to the cluster"
  value       = aws_eks_cluster.eks.endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.eks.name
}

output "eks_cluster_arn" {
  description = "ARN of EKS cluster"
  value       = aws_eks_cluster.eks.arn
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS Worker Nodes"
  value       = aws_iam_role.node.arn
}

output "eks_node_group_name" {
  description = "Name of EKS managed node group"
  value       = aws_eks_node_group.default.node_group_name
}
