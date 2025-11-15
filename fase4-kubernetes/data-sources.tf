data "aws_vpc" "main" {
  cidr_block = "10.100.0.0/16"
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}
