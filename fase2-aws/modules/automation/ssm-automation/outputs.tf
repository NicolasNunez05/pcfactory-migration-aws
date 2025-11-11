# =============================================================================
# OUTPUTS - SSM AUTOMATION
# =============================================================================

output "automation_role_arn" {
  description = "ARN del rol IAM de automation"
  value       = aws_iam_role.automation.arn
}

output "ebs_snapshot_document_name" {
  description = "Nombre del documento de snapshot EBS"
  value       = var.enable_snapshot_automation ? aws_ssm_document.create_ebs_snapshot[0].name : null
}

output "rds_snapshot_document_name" {
  description = "Nombre del documento de snapshot RDS"
  value       = var.enable_backup_automation ? aws_ssm_document.create_rds_snapshot[0].name : null
}

output "patching_document_name" {
  description = "Nombre del documento de patching"
  value       = var.enable_patching_automation ? aws_ssm_document.patch_instances[0].name : null
}

output "automation_schedules" {
  description = "Horarios de automatización configurados"
  value = {
    backups  = var.backup_schedule
    patching = var.patching_schedule
  }
}

output "enabled_automations" {
  description = "Lista de automatizaciones habilitadas"
  value = compact([
    var.enable_backup_automation ? "RDS Backups" : "",
    var.enable_snapshot_automation ? "EBS Snapshots" : "",
    var.enable_patching_automation ? "Patch Management" : ""
  ])
}
