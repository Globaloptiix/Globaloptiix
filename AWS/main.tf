provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token

  }
}

data "aws_availability_zones" "available" {
}

# Set Cluster Name
locals {
  cluster_name = "test-eks-${random_string.suffix.result}"
}

# Name Resource String
resource "random_string" "suffix" {
  length  = 8
  special = false
}

#Setting security groups for worker nodes in the cluster- Worker Nodes
resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}

resource "aws_security_group" "worker_group_mgmt_two" {
  name_prefix = "worker_group_mgmt_two"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "192.168.0.0/16",
    ]
  }
}

# Common
resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}

#VPC Settings
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 2.47"

  name                 = "test-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

# Kubernest used the "shared" to identify new nodes : AWS Requirement ###
  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = local.cluster_name
  cluster_version = "1.20"
  subnets         = module.vpc.private_subnets

# Tags can be changed: From official example in module ###

  tags = {
    Environment = "test"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  vpc_id = module.vpc.vpc_id
### This setup is to take advantage of multiple autoscailing groups and backing up storage in nearest availability zone. Can add setting to specify availability zone
  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t3.small"
      additional_userdata           = "echo foo bar"
      asg_desired_capacity          = 2
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    },
    {
      name                          = "worker-group-2"
      instance_type                 = "t3.medium"
      additional_userdata           = "echo foo bar"
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
      asg_desired_capacity          = 1
    },
  ]
## Common security groups: Mapping roles, users, and accounts so users can access cluster through auth config file.
  worker_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]
  map_roles                            = var.map_roles
  map_users                            = var.map_users
  map_accounts                         = var.map_accounts
}

# Defining Wildcard Domain

# AWS ACM Cert provisioning for domain name
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> v2.0"

  domain_name = var.domain_name
  zone_id     = var.domain_hosted_zone

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  tags = {
    Name = var.domain_name
  }
}

# Retrieving the name / data of the LB provisioned by istio: DNS, Ports from kubernetes. Locals: cut's random strings.
# Istio GET LB DNS name to provision correct DNS records
data "kubernetes_service" "load_balancer_istio" {
  metadata {
    namespace = kubernetes_namespace.istio_system.id
    name      = "istio-ingressgateway"
  }
  depends_on = [helm_release.istio-ingress,kubernetes_namespace.istio_system]
}
locals {
  load_balancer_name_istio = split("-", split(".", data.kubernetes_service.load_balancer_istio.load_balancer_ingress[0].hostname).0).0
}
# Need this to communicate with route53. Retrieve base object from AWS API, because Helm provisions istio, istio provisions LB, Terraform doesn't know anything about the load balancer and needs to know the info.
data "aws_elb" "elbv1_istio" {
  name       = local.load_balancer_name_istio
  depends_on = [helm_release.istio-ingress]
}
