variable "ecr_name" {
    description = "ECR repository name"
    type = string
}

variable "scan_on_push" {
    description = "Enable scanning images during push"
    type = bool
    default = true
}