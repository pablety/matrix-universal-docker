# Instrucciones


## **Configuración completa paso a paso:**


#### **Instalar Docker en Linux:**
```bash

# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com | sh

# Agregar usuario pi al grupo docker
sudo usermod -aG docker pi

# Instalar Docker Compose
sudo apt install -y docker-compose

# Aplicar cambios de grupo
newgrp docker

# Verificar instalación
docker --version
docker-compose --version
```

### **2. Transferir el proyecto Linux**

#### Clonar directamente en Servidor**
```bash
# Desde SSH en la Raspberry Pi
cd /home/pi
git clone https://github.com/pablety/matrix-universal-docker.git
cd matrix-universal-docker
```

### **3. Configurar para Raspberry Pi**

#### **Detectar IP:**
```bash
# Desde SSH en Linux
hostname -I
# Ejemplo: 192.168.1.100
```

#### **Configurar variables de entorno:**
```bash
# Editar archivo .env
nano .env

# Configurar IP de la Raspberry Pi
SERVER_NAME=192.168.1.100
POSTGRES_PASSWORD=raspberry_matrix_2025
ENABLE_REGISTRATION=true
```

### **4. Instalar Matrix en Raspberry Pi**

```bash
# Desde SSH en la Raspberry Pi
# Hacer ejecutable el script
chmod +x build-and-run.sh

# Ejecutar instalación
./build-and-run.sh
```

### **5. Crear primer usuario**

```bash
# Desde SSH en la Raspberry Pi
./scripts/create-user.sh

# Seguir instrucciones:
# Username: pablety
# Password: tu_password_segura
# Admin: y
```


### **Desde otros dispositivos en la red:**
- **PC**: `https://192.168.1.100`
- **Móvil**: `https://192.168.1.100`
- **Tablet**: `https://192.168.1.100`


# Informacion General
## 🚀 Instalación rápida

```bash
# 1. Clonar o descargar el proyecto
git clone <repo-url> matrix-universal-docker
cd matrix-universal-docker

# 2. Ejecutar el instalador
./build-and-run.sh

# 3. ¡Listo! Matrix funcionando en:
# https://localhost
```

## 📋 Requisitos

- **Docker** (versión 20.0+)
- **Docker Compose** (versión 1.29+)
- **2GB RAM** mínimo (4GB recomendado)
- **5GB espacio libre** en disco

### Instalar Docker (si no lo tienes)

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $(whoami)
newgrp docker

# Verificar instalación
docker --version
docker-compose --version
```

## 🔧 Configuración

### Variables de entorno (.env)

Personaliza tu instalación editando el archivo `.env`:

```bash
# Configuración básica
SERVER_NAME=tu-dominio.com          # O tu IP
ENABLE_REGISTRATION=true            # Permitir nuevos usuarios
ENABLE_FEDERATION=false             # Conectar con otros servidores

# Base de datos
POSTGRES_PASSWORD=tu-password-segura

# Configuración avanzada
MAX_UPLOAD_SIZE=50                  # MB
DB_MAX_CONNECTIONS=10
CACHE_FACTOR=1.5
```

### Configuración personalizada

```bash
# Editar configuración antes de iniciar
nano .env

# Reconstruir con nueva configuración
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## 👤 Gestión de usuarios

### Crear primer usuario

```bash
# Método 1: Script automático
./scripts/create-user.sh

# Método 2: Comando directo
docker exec -it matrix-universal register_matrix_user

# Método 3: Comando manual
docker exec -it matrix-universal sudo -u matrix \
  /opt/matrix/env/bin/register_new_matrix_user \
  -c /opt/matrix/homeserver.yaml \
  http://localhost:8008
```

### Crear usuario administrador

```bash
./scripts/create-user.sh admin password123 y
```

## 🌐 Acceso al servidor

### URLs de acceso

- **HTTPS**: `https://localhost` o `https://tu-ip`
- **HTTP**: `http://localhost` o `http://tu-ip`
- **API directa**: `http://localhost:8008`

### Aplicaciones cliente

- **Element Web**: Incluido en `https://localhost`
- **Element Desktop**: [Descargar](https://element.io/get-started)
- **Element Mobile**: Apps Store / Google Play
- **Otros clientes**: [Lista completa](https://matrix.org/clients/)

## 🛠️ Comandos útiles

### Gestión del contenedor

```bash
# Ver estado
docker-compose ps

# Ver logs
docker-compose logs -f

# Reiniciar
docker-compose restart

# Parar
docker-compose down

# Actualizar
docker-compose pull
docker-compose up -d
```

### Gestión de datos

```bash
# Backup completo
./scripts/backup.sh

# Ver estadísticas
docker exec matrix-universal htop

# Entrar al contenedor
docker exec -it matrix-universal bash

# Ver logs de Matrix
docker exec matrix-universal tail -f /var/log/matrix/homeserver.log
```

## 💾 Persistencia de datos

Los datos se guardan automáticamente en:

```
./data/
├── matrix/     # Mensajes, usuarios, salas
├── postgres/   # Base de datos
├── ssl/        # Certificados
└── logs/       # Logs del sistema
```

### Backup y restauración

```bash
# Crear backup
./scripts/backup.sh

# Restaurar backup
tar -xzf backups/matrix_backup_YYYYMMDD_HHMMSS.tar.gz
# Seguir instrucciones en backup_info.txt
```

## 🔐 Seguridad

### Certificados SSL

- **Autofirmados**: Generados automáticamente
- **Válidos por**: 10 años
- **Ubicación**: `./data/ssl/`

### Configuración segura

```bash
# Cambiar password de PostgreSQL
nano .env  # Editar POSTGRES_PASSWORD
docker-compose down
docker-compose up -d

# Deshabilitar registro público
nano .env  # ENABLE_REGISTRATION=false
docker-compose restart
```

## 📊 Monitoreo

### Logs del sistema

```bash
# Logs de Matrix
docker-compose logs matrix-universal

# Logs de PostgreSQL
docker exec matrix-universal tail -f /var/log/postgresql.log

# Logs de Nginx
docker exec matrix-universal tail -f /var/log/nginx/access.log
```

### Estado de servicios

```bash
# Entrar al contenedor
docker exec -it matrix-universal bash

# Ver procesos
supervisorctl status

# Reiniciar servicio específico
supervisorctl restart matrix-synapse
```

## 🔧 Solución de problemas

### Problemas comunes

| Problema | Solución |
|----------|----------|
| "No se puede conectar" | Verificar que el contenedor esté corriendo: `docker-compose ps` |
| "Certificado no válido" | Aceptar certificado autofirmado en el navegador |
| "No puedo crear usuarios" | Verificar que `ENABLE_REGISTRATION=true` en `.env` |
| "Error de base de datos" | Reiniciar: `docker-compose restart` |

### Logs de diagnóstico

```bash
# Diagnóstico completo
docker-compose logs --tail=50

# Verificar conectividad
curl -k https://localhost/_matrix/client/versions

# Verificar puertos
docker-compose ps
```

### Reinicio completo

```bash
# Parar todo
docker-compose down

# Limpiar contenedores
docker system prune -f

# Reiniciar
./build-and-run.sh
```

## 📱 Uso después de la instalación

### Primer uso

1. **Acceder**: Ve a `https://localhost` en tu navegador
2. **Aceptar certificado**: Click en "Avanzado" → "Continuar"
3. **Crear cuenta**: Click en "Crear cuenta"
4. **Configurar perfil**: Añade nombre y foto
5. **¡Listo!**: Ya puedes chatear

### Invitar usuarios

1. **Crear usuarios**: Usa `./scripts/create-user.sh`
2. **Compartir URL**: Comparte `https://tu-ip`
3. **Crear salas**: Desde Element Web
4. **Invitar**: Usa `@usuario:tu-ip`

## 🔄 Actualizaciones

### Actualizar Matrix

```bash
# Actualizar imágenes
docker-compose pull

# Reconstruir
docker-compose build --no-cache

# Reiniciar
docker-compose up -d
```

### Actualizar Element

```bash
# Reconstruir imagen
docker-compose build --no-cache matrix-universal

# Reiniciar
docker-compose up -d
```






# Aparte

## 🔧 **Script PowerShell para gestión remota**

Crea este script en Windows para gestionar tu Matrix desde PowerShell:

```powershell name=matrix-remote-manager.ps1
# Matrix Universal Docker - Gestor Remoto
# Usar desde Windows PowerShell para gestionar Raspberry Pi

param(
    [string]$RaspberryIP = "192.168.1.100",
    [string]$Username = "pi",
    [string]$Action = "status"
)

# Colores para PowerShell
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Info { Write-ColorOutput Cyan $args }
function Write-Success { Write-ColorOutput Green $args }
function Write-Warning { Write-ColorOutput Yellow $args }
function Write-Error { Write-ColorOutput Red $args }

Write-Info "🚀 Matrix Universal Docker - Gestor Remoto"
Write-Info "============================================="
Write-Info "Raspberry Pi: $RaspberryIP"
Write-Info "Usuario: $Username"
Write-Info "Acción: $Action"
Write-Info ""

# Función para ejecutar comandos remotos
function Invoke-SSHCommand {
    param($Command)
    
    Write-Info "Ejecutando: $Command"
    ssh $Username@$RaspberryIP "cd matrix-universal-docker && $Command"
}

# Acciones disponibles
switch ($Action) {
    "status" {
        Write-Info "📋 Verificando estado de Matrix..."
        Invoke-SSHCommand "docker-compose ps"
    }
    
    "start" {
        Write-Info "🚀 Iniciando Matrix..."
        Invoke-SSHCommand "docker-compose up -d"
        Write-Success "✅ Matrix iniciado"
    }
    
    "stop" {
        Write-Info "🛑 Deteniendo Matrix..."
        Invoke-SSHCommand "docker-compose down"
        Write-Success "✅ Matrix detenido"
    }
    
    "restart" {
        Write-Info "🔄 Reiniciando Matrix..."
        Invoke-SSHCommand "docker-compose restart"
        Write-Success "✅ Matrix reiniciado"
    }
    
    "logs" {
        Write-Info "📝 Mostrando logs..."
        Invoke-SSHCommand "docker-compose logs --tail=20"
    }
    
    "create-user" {
        Write-Info "👤 Creando usuario..."
        $NewUsername = Read-Host "Nombre de usuario"
        $NewPassword = Read-Host "Contraseña" -AsSecureString
        $PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewPassword))
        $IsAdmin = Read-Host "¿Es administrador? (y/N)"
        
        $AdminFlag = if ($IsAdmin -eq "y") { "y" } else { "n" }
        Invoke-SSHCommand "./scripts/create-user.sh $NewUsername $PlainPassword $AdminFlag"
    }
    
    "backup" {
        Write-Info "💾 Creando backup..."
        Invoke-SSHCommand "./scripts/backup.sh"
        Write-Success "✅ Backup creado"
    }
    
    "update" {
        Write-Info "🔄 Actualizando Matrix..."
        Invoke-SSHCommand "docker-compose pull && docker-compose build --no-cache && docker-compose up -d"
        Write-Success "✅ Matrix actualizado"
    }
    
    "info" {
        Write-Info "ℹ️ Información del servidor..."
        Invoke-SSHCommand "docker exec matrix-universal supervisorctl status"
        Write-Info ""
        Write-Info "🌐 Acceder desde Windows:"
        Write-Success "   https://$RaspberryIP"
        Write-Info "👤 Crear usuario:"
        Write-Success "   .\matrix-remote-manager.ps1 -Action create-user"
    }
    
    "connect" {
        Write-Info "🔗 Conectando por SSH..."
        ssh $Username@$RaspberryIP
    }
    
    "install" {
        Write-Info "📦 Instalando Matrix en Raspberry Pi..."
        Write-Warning "Esto puede tomar varios minutos..."
        Invoke-SSHCommand "./build-and-run.sh"
        Write-Success "✅ Instalación completada"
        Write-Info "🌐 Acceder: https://$RaspberryIP"
    }
    
    default {
        Write-Info "📋 Acciones disponibles:"
        Write-Info "  status      - Ver estado de servicios"
        Write-Info "  start       - Iniciar Matrix"
        Write-Info "  stop        - Detener Matrix" 
        Write-Info "  restart     - Reiniciar Matrix"
        Write-Info "  logs        - Ver logs"
        Write-Info "  create-user - Crear nuevo usuario"
        Write-Info "  backup      - Crear backup"
        Write-Info "  update      - Actualizar Matrix"
        Write-Info "  info        - Información del servidor"
        Write-Info "  connect     - Conectar por SSH"
        Write-Info "  install     - Instalar Matrix"
        Write-Info ""
        Write-Info "💡 Ejemplo de uso:"
        Write-Success "   .\matrix-remote-manager.ps1 -RaspberryIP 192.168.1.100 -Action status"
    }
}
```

## 🎯 **Uso del script PowerShell**

### **Guardar el script:**
```powershell
# Crear archivo en Windows
New-Item -Path "C:\Users\pablety\matrix-remote-manager.ps1" -ItemType File
# Copiar el contenido del script de arriba
```

### **Usar el script:**
```powershell
# Cambiar a directorio del script
cd C:\Users\pablety

# Ver estado de Matrix
.\matrix-remote-manager.ps1 -RaspberryIP 192.168.1.100 -Action status

# Crear usuario
.\matrix-remote-manager.ps1 -RaspberryIP 192.168.1.100 -Action create-user

# Ver logs
.\matrix-remote-manager.ps1 -RaspberryIP 192.168.1.100 -Action logs

# Crear backup
.\matrix-remote-manager.ps1 -RaspberryIP 192.168.1.100 -Action backup

# Conectar por SSH
.\matrix-remote-manager.ps1 -RaspberryIP 192.168.1.100 -Action connect
```

## 🔧 **Comandos útiles desde Windows PowerShell**

### **Conectar y gestionar:**
```powershell
# Conectar por SSH
ssh pi@192.168.1.100

# Transferir archivos
scp archivo.txt pi@192.168.1.100:/home/pi/

# Ejecutar comando remoto
ssh pi@192.168.1.100 "docker-compose ps"

# Túnel SSH para acceso local (opcional)
ssh -L 8080:localhost:80 pi@192.168.1.100
# Acceder: http://localhost:8080
```

### **Monitoreo remoto:**
```powershell
# Ver logs en tiempo real
ssh pi@192.168.1.100 "cd matrix-universal-docker && docker-compose logs -f"

# Ver estado de servicios
ssh pi@192.168.1.100 "cd matrix-universal-docker && docker-compose ps"

# Ver recursos del sistema
ssh pi@192.168.1.100 "htop"
```

## 🌐 **Configuración de red (opcional)**

### **Configurar IP estática en Raspberry Pi:**
```bash
# Desde SSH en Raspberry Pi
sudo nano /etc/dhcpcd.conf

# Agregar al final:
interface eth0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=8.8.8.8 8.8.4.4

# Reiniciar
sudo reboot
```
