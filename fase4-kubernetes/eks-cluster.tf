resource "aws_eks_cluster" "pcfactory" {
  name            = "${var.project_name}-eks-cluster"
  role_arn        = aws_iam_role.eks_cluster_role.arn
  version         = "1.29"

  vpc_config {
    subnet_ids              = [
      data.aws_subnets.all.ids[0],
      aws_subnet.app_subnet_2.id,
      aws_subnet.app_subnet_3.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]

  tags = {
    Name        = "${var.project_name}-eks-cluster"
    Environment = "production"
    Phase       = "Phase4"
  }
}

resource "aws_subnet" "app_subnet_2" {
  vpc_id            = data.aws_vpc.main.id
  cidr_block        = "10.100.3.0/24"
  availability_zone = "us-east-1b"
  
  tags = {
    Name = "pcfactory-app-subnet-2"
  }
}

resource "aws_subnet" "app_subnet_3" {
  vpc_id            = data.aws_vpc.main.id
  cidr_block        = "10.100.4.0/24"
  availability_zone = "us-east-1c"
  
  tags = {
    Name = "pcfactory-app-subnet-3"
  }
}