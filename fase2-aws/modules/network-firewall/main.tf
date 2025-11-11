# =============================================================================
# AWS NETWORK FIREWALL - PCFACTORY MIGRATION
# =============================================================================

# ========================================
# STATELESS RULE GROUP
# ========================================
resource "aws_networkfirewall_rule_group" "stateless_allow" {
  capacity = 100
  name     = "${var.project_name}-stateless-allow"
  type     = "STATELESS"

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              protocols = [6]
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
              destination_port {
                from_port = 80
                to_port   = 80
              }
            }
          }
        }

        stateless_rule {
          priority = 2
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              protocols = [6]
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
              destination_port {
                from_port = 443
                to_port   = 443
              }
            }
          }
        }
      }
    }
  }

  tags = {
    Name = "${var.project_name}-stateless-allow"
  }
}

# ========================================
# STATEFUL RULE GROUP - BASIC BLOCKING
# ========================================
resource "aws_networkfirewall_rule_group" "stateful_block" {
  capacity = 100
  name     = "${var.project_name}-stateful-block"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_string = <<-EOF
        drop tcp any any -> any 22 (msg:"Block SSH from outside"; sid:1; rev:1;)
        drop tcp any any -> any 3306 (msg:"Block MySQL direct access"; sid:2; rev:1;)
        drop tcp any any -> any 5432 (msg:"Block PostgreSQL direct access"; sid:3; rev:1;)
      EOF
    }
  }

  tags = {
    Name = "${var.project_name}-stateful-block"
  }
}

# ========================================
# STATEFUL RULE GROUP - ADVANCED PROTECTION
# ========================================
resource "aws_networkfirewall_rule_group" "stateful_advanced" {
  capacity = 200
  name     = "${var.project_name}-stateful-advanced"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_string = <<-EOF
        drop tcp any any -> any 3389 (msg:"Block RDP from Internet"; sid:10; rev:1;)
        drop tcp any any -> any 23 (msg:"Block Telnet"; sid:11; rev:1;)
        drop tcp any any -> any 21 (msg:"Block FTP control"; sid:12; rev:1;)
        drop tcp any any -> any 20 (msg:"Block FTP data"; sid:13; rev:1;)
        drop tcp any any -> any 445 (msg:"Block SMB/CIFS"; sid:14; rev:1;)
        drop tcp any any -> any 139 (msg:"Block NetBIOS"; sid:15; rev:1;)
        drop tcp any any -> any 5900 (msg:"Block VNC"; sid:16; rev:1;)
        drop http any any -> any any (msg:"SQL Injection: UNION SELECT"; content:"UNION"; nocase; content:"SELECT"; nocase; distance:0; sid:20; rev:1;)
        drop http any any -> any any (msg:"SQL Injection: OR 1=1"; content:"OR"; nocase; content:"1=1"; nocase; distance:0; sid:21; rev:1;)
        drop http any any -> any any (msg:"SQL Injection: DROP TABLE"; content:"DROP"; nocase; content:"TABLE"; nocase; distance:0; sid:22; rev:1;)
        drop http any any -> any any (msg:"SQL Injection: SQL comments"; content:"--"; sid:23; rev:1;)
        drop http any any -> any any (msg:"XSS attempt: script tag"; content:"<script"; nocase; sid:30; rev:1;)
        drop http any any -> any any (msg:"XSS attempt: javascript protocol"; content:"javascript:"; nocase; sid:31; rev:1;)
        drop http any any -> any any (msg:"XSS attempt: onerror handler"; content:"onerror="; nocase; sid:32; rev:1;)
        drop http any any -> any any (msg:"Path traversal attempt"; content:"../"; sid:40; rev:1;)
        drop udp any any -> any 69 (msg:"Block TFTP"; sid:50; rev:1;)
        drop udp any any -> any 161 (msg:"Block SNMP"; sid:51; rev:1;)
        pass tcp $HOME_NET any -> $EXTERNAL_NET 80 (msg:"Allow HTTP outbound"; sid:100; rev:1;)
        pass tcp $HOME_NET any -> $EXTERNAL_NET 443 (msg:"Allow HTTPS outbound"; sid:101; rev:1;)
        pass udp $HOME_NET any -> $EXTERNAL_NET 53 (msg:"Allow DNS UDP"; sid:102; rev:1;)
        pass tcp $HOME_NET any -> $EXTERNAL_NET 53 (msg:"Allow DNS TCP"; sid:103; rev:1;)
        pass udp $HOME_NET any -> any 123 (msg:"Allow NTP"; sid:104; rev:1;)
      EOF
    }
  }

  tags = {
    Name = "${var.project_name}-stateful-advanced"
  }
}

# ========================================
# FIREWALL POLICY
# ========================================
resource "aws_networkfirewall_firewall_policy" "main" {
  name = "${var.project_name}-fw-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateless_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.stateless_allow.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_block.arn
    }
    
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_advanced.arn
    }
  }

  tags = {
    Name = "${var.project_name}-fw-policy"
  }
}

# ========================================
# NETWORK FIREWALL
# ========================================
resource "aws_networkfirewall_firewall" "main" {
  name                = "${var.project_name}-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id              = var.vpc_id

  dynamic "subnet_mapping" {
    for_each = var.firewall_subnet_ids
    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = {
    Name = "${var.project_name}-firewall"
  }
}

# ========================================
# CLOUDWATCH LOG GROUPS
# ========================================
resource "aws_cloudwatch_log_group" "flow" {
  name              = "/aws/networkfirewall/${var.project_name}/flow"
  retention_in_days = 7
  
  tags = {
    Name        = "${var.project_name}-firewall-flow-logs"
    Environment = var.environment
    Type        = "NetworkFirewall"
  }
}

resource "aws_cloudwatch_log_group" "alert" {
  name              = "/aws/networkfirewall/${var.project_name}/alert"
  retention_in_days = 30
  
  tags = {
    Name        = "${var.project_name}-firewall-alert-logs"
    Environment = var.environment
    Type        = "NetworkFirewall"
  }
}

# ========================================
# LOGGING CONFIGURATION
# ========================================
resource "aws_networkfirewall_logging_configuration" "main" {
  firewall_arn = aws_networkfirewall_firewall.main.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.flow.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.alert.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}
