#!/bin/bash

# Esperar a que Samba esté listo
sleep 30

# Verificar si el dominio ya está configurado
if [ ! -f /var/lib/samba/private/secrets.tdb ]; then
    echo "Configurando dominio Samba..."
    
    # Provisionar el dominio
    samba-tool domain provision \
        --use-rfc2307 \
        --realm=CORP.LOCAL \
        --domain=CORP \
        --adminpass=Password123 \
        --server-role=dc
    
    echo "Dominio provisionado correctamente."
else
    echo "El dominio ya está configurado."
fi

# Crear OUs y usuarios
echo "Creando OUs y usuarios..."
samba-tool ou create "OU=Admins,DC=corp,DC=local" 2>/dev/null || true
samba-tool ou create "OU=Users,DC=corp,DC=local" 2>/dev/null || true
samba-tool ou create "OU=Computers,DC=corp,DC=local" 2>/dev/null || true

# Crear grupos
samba-tool group add "Network-Admins" 2>/dev/null || true
samba-tool group add "VPN-Users" 2>/dev/null || true

# Crear usuarios administradores
for i in 1 2 3; do
    samba-tool user create "admin$i" "Admin${i}Pass123!" \
        --userou="OU=Admins" \
        --given-name="Admin" \
        --surname="$i" \
        2>/dev/null || true
    
    samba-tool group addmembers "Network-Admins" "admin$i" 2>/dev/null || true
done

# Crear usuarios normales
for i in 1 2 3 4 5 6 7 8; do
    samba-tool user create "user$i" "User${i}Pass123!" \
        --userou="OU=Users" \
        --given-name="User" \
        --surname="$i" \
        2>/dev/null || true
    
    samba-tool group addmembers "VPN-Users" "user$i" 2>/dev/null || true
done

echo "Configuración de Active Directory completada."