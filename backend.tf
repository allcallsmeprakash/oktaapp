terraform {
  backend "s3" {
    bucket = "training-usecases"
    key    = "okta/terraform.tfstate"
    region = "us-east-1"
  }
}
