# Migración de Infraestructura de PCFactory a AWS

Este proyecto documenta la migración de la infraestructura on-premise de PCFactory hacia una arquitectura cloud-native en AWS.

## Estructura del Proyecto

- `fase1-onpremise/`: Simulación de la infraestructura actual usando Docker
- `fase2-aws/`: Infraestructura como código con Terraform para AWS
- `fase3-cicd/`: Pipeline de CI/CD con Jenkins
- `fase4-kubernetes/`: Modernización con Kubernetes (EKS)
- `docs/`: Documentación y diagramas

## Equipo
- Nicolás Núñez
- José Catalán

## Instrucciones de Uso
-




## Servicio de Active Directory Simulado

Para esta simulación, hemos implementado un controlador de dominio básico usando Samba4 con las siguientes características:

- **Dominio:** CORP (corp.local)
- **Controlador Principal:** dc1.corp.local (10.20.20.10)
- **Controlador Secundario:** dc2.corp.local (10.20.20.11) - conceptual
- **Usuario Administrador:** Administrator (contraseña: Password123)

### Estructura Conceptual de Usuarios y Grupos

Aunque no se han creado físicamente en la simulación, el diseño contempla:

**Usuarios:**
- 3 administradores: admin1, admin2, admin3
- 8 usuarios remotos: user1, user2, ..., user8

**Grupos de Seguridad:**
- Network-Admins (contiene admin1, admin2, admin3)
- VPN-Users (contiene user1 a user8)

**Nota:** En un entorno de producción real, estos usuarios y grupos se crearían en el Active Directory y se utilizarían para políticas de acceso y autenticación.