# ========================================
# CLIENT VPN ENDPOINT
# ========================================

resource "aws_ec2_client_vpn_endpoint" "main" {
  description            = "${var.project_name} Client VPN Endpoint"
  server_certificate_arn = var.server_certificate_arn
  client_cidr_block      = var.vpn_cidr
  vpc_id                 = var.vpc_id
  split_tunnel           = true
  
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_root_certificate_arn
  }

 connection_log_options {
  enabled               = true
  cloudwatch_log_group  = aws_cloudwatch_log_group.vpn_logs.name
  cloudwatch_log_stream = "${var.project_name}-vpn-connections"
}

  dns_servers = ["10.20.0.2"]

  tags = {
    Name = "${var.project_name}-client-vpn"
  }
}

# ========================================
# NETWORK ASSOCIATIONS
# ========================================

resource "aws_ec2_client_vpn_network_association" "main" {
  count                  = length(var.vpn_subnet_ids)
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  subnet_id              = var.vpn_subnet_ids[count.index]
}

# ========================================
# AUTHORIZATION RULES
# ========================================

resource "aws_ec2_client_vpn_authorization_rule" "all_network" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  target_network_cidr    = "10.20.0.0/16"
  authorize_all_groups   = true
  description            = "Allow access to entire VPC"
}

# ========================================
# CLOUDWATCH LOG GROUP
# ========================================

resource "aws_cloudwatch_log_group" "vpn_logs" {
  name              = "/aws/clientvpn/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-vpn-logs"
  }
}

# Log stream para conexiones VPN
resource "aws_cloudwatch_log_stream" "vpn_connections" {
  name           = "${var.project_name}-vpn-connections"
  log_group_name = aws_cloudwatch_log_group.vpn_logs.name
}