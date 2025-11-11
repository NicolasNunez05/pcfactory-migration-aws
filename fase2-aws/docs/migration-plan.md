# Plan de Migración a AWS para PCFactory

## Objetivo

Migrar la infraestructura on-premise de PCFactory a AWS de manera segura, automatizada y escalable mediante infraestructura como código.

## Fases del proyecto

1. **Diseño y Preparación**  
   - Definición de arquitectura AWS  
   - Diseño de red, seguridad y segmentación VLAN  
   - Planificación CI/CD y automatización Terraform  

2. **Desarrollo del Código Terraform**  
   - Creación de módulos para VPC, EC2, RDS, ALB, IAM, y otros  
   - Definición de backend remoto para estado Terraform  
   - Configuración de providers y variables  

3. **Pruebas y Validaciones**  
   - Despliegues en entorno de desarrollo  
   - Pruebas funcionales y de seguridad  
   - Corrección y ajustes necesarios  

4. **Ejecución de la Migración**  
   - Backup de datos on-premise  
   - Deploy en AWS  
   - Migración de bases de datos y servicios  

5. **Verificación Post-Migración**  
   - Validación de servicios  
   - Monitoreo y ajuste  
   - Documentación final y capacitación  


## Equipo responsable

- Infraestructura AWS: implementación y soporte técnico  
- Aplicaciones: validación funcional y pruebas  
- Gestión de proyecto: control y seguimiento  

## Riesgos y mitigación

- Retrasos en las pruebas → Plan de contingencia y rollback  
- Fallos en la conexión → Validaciones y pruebas previas exhaustivas  
- Cambios de última hora → Gestión de cambio ágil y comunicación constante  

