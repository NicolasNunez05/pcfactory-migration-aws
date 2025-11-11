# ============================================================================
# CONFIGURACIÓN CENTRALIZADA DE UMBRALES DE ALARMAS
# ============================================================================
# Este archivo centraliza todos los thresholds para facilitar ajustes

locals {
  # -------------------------------------------------------------------------
  # UMBRALES DE EC2
  # -------------------------------------------------------------------------
  ec2_thresholds = {
    cpu_high           = 80  # % - CPU crítica
    cpu_warning        = 70  # % - CPU advertencia
    memory_high        = 85  # % - Memoria crítica
    memory_warning     = 75  # % - Memoria advertencia
    disk_high          = 90  # % - Disco crítico
    disk_warning       = 80  # % - Disco advertencia
    status_check_fails = 1   # Count - Fallo de status check
  }

  # -------------------------------------------------------------------------
  # UMBRALES DE RDS
  # -------------------------------------------------------------------------
  rds_thresholds = {
    cpu_high              = 75   # % - CPU crítica
    cpu_warning           = 60   # % - CPU advertencia
    memory_low            = 1073741824  # Bytes (1 GB) - Memoria libre mínima
    connections_high      = 80   # % de max_connections
    read_latency_high     = 0.1  # Segundos (100ms)
    write_latency_high    = 0.1  # Segundos (100ms)
    storage_low           = 10   # % - Espacio libre mínimo
    replica_lag_high      = 30   # Segundos - Lag de réplica
  }

  # -------------------------------------------------------------------------
  # UMBRALES DE ALB
  # -------------------------------------------------------------------------
  alb_thresholds = {
    target_5xx_count      = 10   # Count - Errores 5xx por minuto
    target_4xx_count      = 50   # Count - Errores 4xx por minuto
    response_time_high    = 3    # Segundos - Tiempo de respuesta
    unhealthy_hosts       = 1    # Count - Hosts no saludables
    connection_errors     = 5    # Count - Errores de conexión
  }

  # -------------------------------------------------------------------------
  # UMBRALES DE CLIENT VPN
  # -------------------------------------------------------------------------
  vpn_thresholds = {
    active_connections_high = 50   # Count - Conexiones activas máximas
    auth_failures_high      = 5    # Count - Fallos de autenticación por minuto
    bytes_in_high           = 1073741824  # Bytes (1 GB/min)
    bytes_out_high          = 1073741824  # Bytes (1 GB/min)
  }

  # -------------------------------------------------------------------------
  # UMBRALES DE NETWORK FIREWALL
  # -------------------------------------------------------------------------
  firewall_thresholds = {
    packets_dropped_high = 1000  # Count - Paquetes descartados por minuto
    invalid_packets_high = 100   # Count - Paquetes inválidos por minuto
  }

  # -------------------------------------------------------------------------
  # PERÍODOS DE EVALUACIÓN
  # -------------------------------------------------------------------------
  evaluation_periods = {
    immediate = 1   # 1 período (detección inmediata)
    short     = 2   # 2 períodos (5-10 min)
    medium    = 3   # 3 períodos (15 min)
    long      = 5   # 5 períodos (25 min)
  }

  # -------------------------------------------------------------------------
  # PERÍODOS DE DATOS
  # -------------------------------------------------------------------------
  periods = {
    one_minute    = 60    # 1 minuto
    five_minutes  = 300   # 5 minutos
    fifteen_minutes = 900 # 15 minutos
  }
}
