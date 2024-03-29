#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

### fetches crendentails from vault cluster

data "vault_aws_access_credentials" "creds" {
  backend = "aws"
  role    = "dynamic-aws-creds-vault-admin"
}

### fetches aws access and secert key form vault
provider "aws" {
  region	 = var.aws_region
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key  
}

resource "aws_iam_role" "demo-cluster" {
  name = "terraform-eks-demo-cluster"

 assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "demo-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.demo-cluster.name
}

resource "aws_iam_role_policy_attachment" "demo-cluster-AmazonEKSServicePolicy" { 
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy" 
  role = aws_iam_role.demo-cluster.name 
}

resource "aws_security_group" "demo-cluster" {
  name        = "terraform-eks-demo-cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.demo.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-eks-demo"
  }
}

resource "aws_security_group_rule" "demo-cluster-ingress-workstation-https" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.demo-cluster.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "demo-cluster-ingress-workstation-8080" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 8080
  protocol          = "tcp"
  security_group_id = aws_security_group.demo-cluster.id
  to_port           = 8080
  type              = "ingress"
}

resource "aws_security_group_rule" "demo-cluster-ingress-workstation-80" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.demo-cluster.id
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "demo-cluster-ingress-workstation-5000" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 5000
  protocol          = "tcp"
  security_group_id = aws_security_group.demo-cluster.id
  to_port           = 5000
  type              = "ingress"
}

resource "aws_eks_cluster" "demo" {
  name     = var.cluster-name
  role_arn = aws_iam_role.demo-cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.demo-cluster.id]
    subnet_ids         = aws_subnet.demo[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.demo-cluster-AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.demo-cluster-AmazonEKSClusterPolicy,
  ]
}


