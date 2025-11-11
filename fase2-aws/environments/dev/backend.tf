terraform {
  backend "s3" {
    bucket         = "pcfactory-terraform-state-787124622819"
    key            = "fase2-aws/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "pcfactory-terraform-locks"
    encrypt        = true
  }
}
