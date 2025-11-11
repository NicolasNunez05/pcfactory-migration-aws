# =============================================================================
# SECURITY GROUPS - PCFACTORY MIGRATION
# =============================================================================
# Este módulo gestiona Security Groups, IAM Users/Groups y NAT Gateway
# Implementa principio de Least Privilege y defensa en profundidad
# Ultima actualizacion: 2025-11-08
# =============================================================================

# =============================================================================
# ALB SECURITY GROUP
# =============================================================================
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security Group para ALB - Permite HTTP y HTTPS desde Internet"
  vpc_id      = var.vpc_id
  
  ingress {
    description = "HTTP from Internet IPv4"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description      = "HTTP from Internet IPv6"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    description = "HTTPS from Internet IPv4"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description      = "HTTPS from Internet IPv6"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
  }
  
  egress {
    description = "Allow all outbound IPv4 to App instances"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    description      = "Allow all outbound IPv6 to App instances"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
  
  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# =============================================================================
# APP SECURITY GROUP (SIN REGLAS INLINE - Evita dependencia circular)
# =============================================================================
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg"
  description = "Security Group para instancias de aplicacion Flask"
  vpc_id      = var.vpc_id
  
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

# =============================================================================
# DB SECURITY GROUP (SIN REGLAS INLINE - Evita dependencia circular)
# =============================================================================
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Security Group para RDS PostgreSQL"
  vpc_id      = var.vpc_id
  
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

# =============================================================================
# REGLAS SEPARADAS PARA APP_SG (Evita dependencia circular)
# =============================================================================

resource "aws_security_group_rule" "app_from_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
  description              = "HTTP from ALB on port 8080"
}

resource "aws_security_group_rule" "app_from_vpn" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = aws_security_group.app_sg.id
  cidr_blocks       = ["172.16.0.0/22"]
  description       = "HTTP from VPN users for troubleshooting"
}

resource "aws_security_group_rule" "app_icmp" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  security_group_id = aws_security_group.app_sg.id
  cidr_blocks       = ["172.16.0.0/22", "10.20.0.0/16"]
  description       = "ICMP (ping) from VPN and VPC for troubleshooting"
}

# =============================================================================
# REGLAS SEPARADAS PARA DB_SG (Evita dependencia circular)
# =============================================================================

resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = aws_security_group.app_sg.id
  description              = "PostgreSQL from App instances only"
}

# =============================================================================
# IAM USERS Y GROUPS
# =============================================================================

resource "aws_iam_group" "administradores_cloud" {
  name = "AdministradoresCloud"
}

resource "aws_iam_group_policy_attachment" "admin_policy" {
  group      = aws_iam_group.administradores_cloud.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user" "admin1" {
  name = "nicolas.nunez"
  tags = {
    Role = "Admin"
  }
}

resource "aws_iam_user" "admin2" {
  name = "jose.catalan"
  tags = {
    Role = "Admin"
  }
}

resource "aws_iam_user" "admin3" {
  name = "carla.reyes"
  tags = {
    Role = "Admin"
  }
}

resource "aws_iam_user_group_membership" "admin1_membership" {
  user = aws_iam_user.admin1.name
  groups = [
    aws_iam_group.administradores_cloud.name
  ]
}

resource "aws_iam_user_group_membership" "admin2_membership" {
  user = aws_iam_user.admin2.name
  groups = [
    aws_iam_group.administradores_cloud.name
  ]
}

resource "aws_iam_user_group_membership" "admin3_membership" {
  user = aws_iam_user.admin3.name
  groups = [
    aws_iam_group.administradores_cloud.name
  ]
}

resource "aws_iam_group" "usuarios_aplicacion" {
  name = "UsuariosAplicacion"
}

resource "aws_iam_group_policy_attachment" "users_policy" {
  group      = aws_iam_group.usuarios_aplicacion.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_user" "user1" {
  name = "felipe.rojas"
  tags = {
    Role = "Ventas"
  }
}

resource "aws_iam_user" "user2" {
  name = "javiera.soto"
  tags = {
    Role = "Asistencia"
  }
}

resource "aws_iam_user" "user3" {
  name = "matias.perez"
  tags = {
    Role = "Ventas"
  }
}

resource "aws_iam_user" "user4" {
  name = "camila.gonzalez"
  tags = {
    Role = "Asistencia"
  }
}

resource "aws_iam_user" "user5" {
  name = "diego.castro"
  tags = {
    Role = "Ventas"
  }
}

resource "aws_iam_user" "user6" {
  name = "valentina.diaz"
  tags = {
    Role = "Asistencia"
  }
}

resource "aws_iam_user" "user7" {
  name = "andres.silva"
  tags = {
    Role = "Ventas"
  }
}

resource "aws_iam_user" "user8" {
  name = "isidora.morales"
  tags = {
    Role = "Asistencia"
  }
}

resource "aws_iam_user_group_membership" "user1_membership" {
  user = aws_iam_user.user1.name
  groups = [
    aws_iam_group.usuarios_aplicacion.name
  ]
}

resource "aws_iam_user_group_membership" "user2_membership" {
  user = aws_iam_user.user2.name
  groups = [
    aws_iam_group.usuarios_aplicacion.name
  ]
}

resource "aws_iam_user_group_membership" "user3_membership" {
  user = aws_iam_user.user3.name
  groups = [
    aws_iam_group.usuarios_aplicacion.name
  ]
}

resource "aws_iam_user_group_membership" "user4_membership" {
  user = aws_iam_user.user4.name
  groups = [
    aws_iam_group.usuarios_aplicacion.name
  ]
}

resource "aws_iam_user_group_membership" "user5_membership" {
  user = aws_iam_user.user5.name
  groups = [
    aws_iam_group.usuarios_aplicacion.name
  ]
}

resource "aws_iam_user_group_membership" "user6_membership" {
  user = aws_iam_user.user6.name
  groups = [
    aws_iam_group.usuarios_aplicacion.name
  ]
}

resource "aws_iam_user_group_membership" "user7_membership" {
  user = aws_iam_user.user7.name
  groups = [
    aws_iam_group.usuarios_aplicacion.name
  ]
}

resource "aws_iam_user_group_membership" "user8_membership" {
  user = aws_iam_user.user8.name
  groups = [
    aws_iam_group.usuarios_aplicacion.name
  ]
}



# =============================================================================
# NAT GATEWAY
# =============================================================================

resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_ids[0]
  
  tags = {
    Name = "${var.project_name}-nat-gw"
  }
  
  depends_on = [aws_eip.nat]
}
