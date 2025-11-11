# =============================================================================
# OUTPUTS - AWS CONFIG
# =============================================================================

output "config_recorder_id" {
  description = "ID del Config Recorder"
  value       = aws_config_configuration_recorder.main.id
}

output "config_role_arn" {
  description = "ARN del rol IAM de Config"
  value       = aws_iam_role.config.arn
}

output "delivery_channel_id" {
  description = "ID del delivery channel"
  value       = aws_config_delivery_channel.main.id
}

output "enabled_rules_count" {
  description = "Número de reglas habilitadas"
  value       = var.enable_managed_rules ? 10 : 0
}

output "config_rules" {
  description = "Lista de reglas Config creadas"
  value = var.enable_managed_rules ? [
    aws_config_config_rule.s3_encryption[0].name,
    aws_config_config_rule.rds_encryption[0].name,
    aws_config_config_rule.ebs_encryption[0].name,
    aws_config_config_rule.sg_restricted[0].name,
    aws_config_config_rule.cloudtrail_enabled[0].name,
    aws_config_config_rule.iam_password_policy[0].name,
    aws_config_config_rule.root_mfa[0].name,
    aws_config_config_rule.ec2_in_vpc[0].name,
    aws_config_config_rule.rds_backup[0].name,
    aws_config_config_rule.s3_versioning[0].name
  ] : []
}
