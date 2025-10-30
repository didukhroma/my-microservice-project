terraform {
    backend "s3" {
        bucket = "home-work-lesson-5-30-10-2025"
        key = "lesson-5/terraform.tfstate"
        region = "us-west-2"
        dynamodb_table = "terraform-locks"
        encrypt = true
    }
}