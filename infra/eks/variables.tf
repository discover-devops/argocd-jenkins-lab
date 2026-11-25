variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "project" {
  type    = string
  default = "argocd-lab"
}

variable "cluster_name" {
  description = "Must match cluster_name in infra/ec2, which tagged the subnets"
  type        = string
  default     = "argocd-lab-eks"
}

variable "node_instance_type" {
  type    = string
  default = "t3.large"
}

variable "node_count" {
  type    = number
  default = 2
}
