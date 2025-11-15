output "cluster_name" {
  value = aws_eks_cluster.pcfactory.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.pcfactory.endpoint
}

output "cluster_arn" {
  value = aws_eks_cluster.pcfactory.arn
}

output "cluster_version" {
  value = aws_eks_cluster.pcfactory.version
}

output "node_group_id" {
  value = aws_eks_node_group.pcfactory.id
}
