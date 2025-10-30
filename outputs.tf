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

