variable "local_log_groups" {
  description = "Map de log groups locales para agregar a centralizado"
  type = map(object({
    name = string
    arn  = string
    type = string
  }))
  default = {}
}

# COMENTADO TEMPORALMENTE - Problemas con permisos roleArn
# resource "aws_cloudwatch_log_subscription_filter" "app_to_central" {
#   for_each = { for k, v in var.local_log_groups : k => v if v.type == "application" }
#
#   name            = "${var.project_name}-${each.key}-to-central"
#   log_group_name  = each.value.name
#   filter_pattern  = ""
#   destination_arn = aws_cloudwatch_log_group.centralized_app.arn
# }

# resource "aws_cloudwatch_log_subscription_filter" "infra_to_central" {
#   for_each = { for k, v in var.local_log_groups : k => v if v.type == "infrastructure" }
#
#   name            = "${var.project_name}-${each.key}-to-central"
#   log_group_name  = each.value.name
#   filter_pattern  = ""
#   destination_arn = aws_cloudwatch_log_group.centralized_infra.arn
# }

# resource "aws_cloudwatch_log_subscription_filter" "security_to_central" {
#   for_each = { for k, v in var.local_log_groups : k => v if v.type == "security" }
#
#   name            = "${var.project_name}-${each.key}-to-central"
#   log_group_name  = each.value.name
#   filter_pattern  = ""
#   destination_arn = aws_cloudwatch_log_group.centralized_security.arn
# }
