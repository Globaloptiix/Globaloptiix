# Mandatory
# Chnage This
variable "domain_hosted_zone" {
  default = "Z04611911L2GP3PRGK0K0"
}
# Mandatory
# Change This
variable "domain_name" {
  default = "cloud-globaloptiix.com"
}


variable "region" {
  default = "us-east-1"
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)

  default = [
    "807129202839"
  ]
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

   default = [
    {
      rolearn  = "arn:aws:iam::66666666666:role/role1"
      username = "role1"
      groups   = ["system:masters"]
    },
  ]
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = [
    {
      userarn  = "arn:aws:iam::807129202839:user/tonystark"
      username = "tonystark"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::807129202839:user/tonystark-optiix"
      username = "tonystark-optiix"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::807129202839:user/terraform"
      username = "terraform"
      groups   = ["system:masters"]
    },
  ]
}
