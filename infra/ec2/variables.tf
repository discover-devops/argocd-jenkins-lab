variable "region" {
  description = "AWS region for the whole lab"
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Name prefix and Project tag for every resource"
  type        = string
  default     = "argocd-lab"
}

variable "cluster_name" {
  description = "EKS cluster name, used to tag the subnets in Part 2"
  type        = string
  default     = "argocd-lab-eks"
}

variable "instance_type" {
  description = "Size of the jumpbox and Jenkins server"
  type        = string
  default     = "t3.medium"
}

variable "allowed_cidr" {
  description = "Who may reach SSH and Jenkins. 0.0.0.0/0 is for a short lab only"
  type        = string
  default     = "0.0.0.0/0"
}
