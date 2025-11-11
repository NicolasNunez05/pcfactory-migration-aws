# Fase 1: Infraestructura On-Premise PCFactory

## ARQUITECTURA IMPLEMENTADA

### Diagrama de Red Real

[CONTAINER NETWORKING - DOCKER]
|
├── vlan10_mgmt (172.31.10.0/24) - Gestión
│ ├── dns.corp.local (172.31.10.10)
│ ├── ntp.corp.local (172.31.10.13)
│ ├── ad.corp.local (172.31.10.11)
│ ├── db.corp.local (172.31.10.12)
│ ├── app.corp.local (172.31.10.14)
│ └── web.corp.local (172.31.10.15)
│
├── vlan20_db (172.31.20.0/24) - Base de Datos
│ ├── db.corp.local (172.31.20.12)
│ └── ad.corp.local (172.31.20.10)
│
├── vlan30_app (172.31.30.0/24) - Aplicación
│ ├── app.corp.local (172.31.30.14)
│ └── web.corp.local (172.31.30.15)
│
└── vlan40_dmz (172.31.40.0/24) - Zona Desmilitarizada
└── web.corp.local (172.31.40.15)


### Tabla de Servicios y IPs
| Servicio | IP Principal | VLAN | Función | Puertos |
|----------|--------------|------|----------|---------|
| **Nginx (Web)** | 172.31.40.15 | vlan40_dmz | Reverse Proxy | 80, 443 |
| **Flask App** | 172.31.30.14 | vlan30_app | API REST | 8080 |
| **PostgreSQL** | 172.31.20.12 | vlan20_db | Base de Datos | 5432 |
| **DNS** | 172.31.10.10 | vlan10_mgmt | Resolución interna | 53 |
| **NTP** | 172.31.10.13 | vlan10_mgmt | Sincronización | 123 |
| **Active Directory** | 172.31.20.10 | vlan20_db | Autenticación | 389,636 |

**Nota:** Algunos servicios tienen múltiples IPs para conectividad entre VLANs.

## INSTALACIÓN Y DESPLIEGUE

### Prerrequisitos
- Docker Engine 20.10+
- Docker Compose 2.0+
- Git

### Comandos de Despliegue

```bash
# 1. Clonar el repositorio (si aplica)
git clone <url-del-repositorio>
cd pcfactory-migration/fase1-onpremise

# 2. Verificar la configuración
docker-compose config

# 3. Desplegar toda la infraestructura
docker-compose up -d

# 4. Verificar que todos los servicios estén ejecutándose
docker-compose ps





### SOLUCIÓN DE PROBLEMAS
## Comandos de Diagnóstico

# Reiniciar servicios específicos
docker-compose restart web app db

# Ver todos los logs
docker-compose logs

# Verificar variables de entorno
docker exec app env | grep DB

# Probar conectividad de base de datos
docker exec app python -c "
import psycopg2
try:
    conn = psycopg2.connect(
        host='db.corp.local',
        database='pcfactory', 
        user='postgres',
        password='password'
    )
    print('Conexión a DB exitosa')
except Exception as e:
    print('Error:', e)
"