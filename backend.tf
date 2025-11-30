
terraform {
  backend "s3" {
    bucket = "terraform-state-final-project-devops"
    key            = "final-project-devops/terraform.tfstate"
    region         = "us-west-2"
    use_lockfile = true
    encrypt        = true
  }
}