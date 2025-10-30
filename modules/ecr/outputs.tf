output "repository_name" {
    value = aws_ecr_repository.this.name
    description = "ECR repository name"
}

output "repository_arn" {
  value       = aws_ecr_repository.this.arn
  description = "ARN ECR repository"
}

output "repository_url" {
  value       = aws_ecr_repository.this.repository_url
  description = "Full URL (registry/repo)"
}