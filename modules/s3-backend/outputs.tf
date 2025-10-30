output "bucket_name" {
  description = "S3 bucket name for states"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for locking states"
  value       = aws_dynamodb_table.terraform_locks.name
}