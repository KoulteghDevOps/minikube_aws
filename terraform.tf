terraform {
  backend "local" {
    path = "/opt/mikikube.tfstate"
  }
}

provider "aws" {
  region = "us-east-1"  # Replace with your desired region
}

data "aws_ami" "ami" {
  most_recent = true
  name_regex  = "Centos-8-DevOps-Practice"
  owners      = ["973714476881"]
}

data "external" "zone" {
  program = ["bash", "${path.root}/route53"]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "minikube"
  cidr = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = []
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  enable_nat_gateway = false
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "minikube-spot-instance"

  create_spot_instance = true
#  spot_price           = "0.60"
  spot_type              = "persistent"
  cluster_name           = "minikube-instance"
  instance_type          = "t3.medium"
  ssh_public_key = "~/.ssh/id_rsa.pub"
#  key_name               = "user1"
  aws_subnet_id = element(lookup(module.vpc, "public_subnets", null), 0)
  hosted_zone = data.external.zone.result.id
  hosted_zone_private = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "minikube-instance"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y curl conntrack-tools",
      "sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo",
      "sudo dnf install -y docker-ce docker-ce-cli containerd.io",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\"",
      "sudo chmod +x kubectl",
      "sudo mv kubectl /usr/local/bin/",
      "curl -LO \"https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm\"",
      "sudo rpm -ivh minikube-latest.x86_64.rpm",
      "minikube start --driver=docker"
    ]
  }
}

#module "minikube" {
#  source = "github.com/scholzj/terraform-aws-minikube"
#
#  aws_region    = "us-east-1"
#  cluster_name  = "minikube"
#  aws_instance_type = "t3.medium"
#  ssh_public_key = "~/.ssh/id_rsa.pub"
#  aws_subnet_id = element(lookup(module.vpc, "public_subnets", null), 0)
#  hosted_zone = data.external.zone.result.id
#  hosted_zone_private = false
#
#  tags = {
#    Name = "minikube"
#  }

#resource "aws_instance" "minikube" {
#  ami           = "ami-0c94855ba95c71c99"  # Replace with the CentOS 8 AMI ID in your desired region
#  instance_type = "t3.medium"  # Replace with your desired instance type
#  aws_region    = "us-east-1"
#  cluster_name  = "minikube-instance"
#  aws_instance_type = "t3.medium"
#  ssh_public_key = "~/.ssh/id_rsa.pub"
#  aws_subnet_id = element(lookup(module.vpc, "public_subnets", null), 0)
#  hosted_zone = data.external.zone.result.id
#  hosted_zone_private = false
#
#  tags = {
#    Name = "minikube-instance"
#  }
#  key_name = "my-key-pair"  # Replace with the name of your EC2 key pair
#
#  tags = {
#    Name = "minikube-instance"
#  }
#  provisioner "remote-exec" {
#    inline = [
#      "sudo yum update -y",
#      "sudo yum install -y curl conntrack-tools",
#      "sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo",
#      "sudo dnf install -y docker-ce docker-ce-cli containerd.io",
#      "sudo systemctl start docker",
#      "sudo systemctl enable docker",
#      "sudo curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\"",
#      "sudo chmod +x kubectl",
#      "sudo mv kubectl /usr/local/bin/",
#      "curl -LO \"https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm\"",
#      "sudo rpm -ivh minikube-latest.x86_64.rpm",
#      "minikube start --driver=docker"
#    ]
#  }
#}