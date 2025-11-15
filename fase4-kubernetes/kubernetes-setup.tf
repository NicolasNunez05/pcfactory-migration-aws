# kubernetes-setup.tf
# Configurar kubeconfig automáticamente

resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${aws_eks_cluster.pcfactory.name} --region us-east-1"
  }
  
  depends_on = [aws_eks_cluster.pcfactory]
}
