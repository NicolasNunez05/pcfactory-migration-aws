output "document_name" {
  value       = aws_ssm_document.patch_baseline.name
  description = "Nombre del documento SSM para parcheo"
}


output "key_arn" {
  value = aws_kms_key.this.arn
}