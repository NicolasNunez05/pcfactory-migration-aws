output "overview_dashboard_name" {
  description = "Nombre del dashboard Overview"
  value       = aws_cloudwatch_dashboard.overview.dashboard_name
}

output "overview_dashboard_arn" {
  description = "ARN del dashboard Overview"
  value       = aws_cloudwatch_dashboard.overview.dashboard_arn
}

output "networking_dashboard_name" {
  description = "Nombre del dashboard Networking"
  value       = aws_cloudwatch_dashboard.networking.dashboard_name
}

output "compute_dashboard_name" {
  description = "Nombre del dashboard Compute"
  value       = aws_cloudwatch_dashboard.compute.dashboard_name
}

output "database_dashboard_name" {
  description = "Nombre del dashboard Database"
  value       = aws_cloudwatch_dashboard.database.dashboard_name
}

output "security_dashboard_name" {
  description = "Nombre del dashboard Security"
  value       = aws_cloudwatch_dashboard.security.dashboard_name
}

output "all_dashboard_names" {
  description = "Lista de todos los dashboards creados"
  value = [
    aws_cloudwatch_dashboard.overview.dashboard_name,
    aws_cloudwatch_dashboard.networking.dashboard_name,
    aws_cloudwatch_dashboard.compute.dashboard_name,
    aws_cloudwatch_dashboard.database.dashboard_name,
    aws_cloudwatch_dashboard.security.dashboard_name
  ]
}

output "dashboard_urls" {
  description = "URLs directas a los dashboards en la consola de AWS"
  value = {
    overview   = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.overview.dashboard_name}"
    networking = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.networking.dashboard_name}"
    compute    = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.compute.dashboard_name}"
    database   = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.database.dashboard_name}"
    security   = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.security.dashboard_name}"
  }
}

