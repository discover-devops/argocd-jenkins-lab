output "cluster_name" {
  value = aws_eks_cluster.lab.name
}

output "kubernetes_version" {
  value = aws_eks_cluster.lab.version
}

output "connect_command" {
  description = "Run this to point kubectl at the new cluster"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.lab.name} --region ${var.region}"
}
