# Arquitectura AWS Proyecto PCFactory

Este documento describe la arquitectura desplegada en AWS para la migración y automatización de la infraestructura on-premise de PCFactory.

## Componentes principales

- **VPC segmentada** en subredes públicas y privadas para seguridad y separación de servicios.
- **EC2**: instancias para servidores de aplicación y bases de datos.
- **RDS**: base de datos relacional gestionada para alta disponibilidad y escalabilidad.
- **Application Load Balancer (ALB)**: para distribuir el tráfico entrante de forma eficiente.
- **IAM**: para la gestión de identidades y permisos con principios de mínimo privilegio.
- **S3**: almacenamiento para estado remoto de Terraform, backups y archivos estáticos.
- **DynamoDB**: tabla para bloqueo de estado remotos de Terraform y evitar condiciones de carrera.

## Descripción detallada

- Subredes públicas gestionan los servicios expuestos a internet, como el ALB.
- Subredes privadas alojan bases de datos y servicios backend no accesibles desde internet.
- Seguridad configurada con grupos de seguridad y Network ACLs para controlar estrictamente el tráfico.
- Se implementa infraestructura como código con Terraform para replicabilidad y auditoría.