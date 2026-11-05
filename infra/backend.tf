terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket = "pgr301-terraform-state"
    key    = "wishifai/k28/terraform.tfstate"
    region = "eu-west-1"
  }
}
