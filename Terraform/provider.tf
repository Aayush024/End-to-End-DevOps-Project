provider "aws" {
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket       = "ayush-devops-project-tfstate-2001"
    region       = "ap-south-1"
    key          = "end-to-end-devops/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}
