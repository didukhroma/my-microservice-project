output "s3_bucket_name" {
    description = "S3-bucket name for states"
    value = module.s3_backend.bucket_name
}

output "dynamodb_table_name" {
    description = "DynamoDB table name for locking states"
    value = module.s3_backend.dynamodb_table_name
}

output "ecr_repository_url" {
    description = "Full URL (registry/repo)"
    value = module.ecr.repository_url
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint for connecting to the cluster"
  value       = module.eks.eks_cluster_endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.eks_cluster_name
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS Worker Nodes"
  value       = module.eks.eks_node_role_arn
}