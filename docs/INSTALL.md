# 📖 Guía de Instalación - Matrix Universal Docker

Guía completa paso a paso para instalar tu servidor Matrix Universal.

## 🎯 Resumen rápido

```bash
# 1. Descargar
git clone https://github.com/pablety/matrix-universal-docker.git
cd matrix-universal-docker

# 2. Instalar
./build-and-run.sh

# 3. Crear usuario
./scripts/create-user.sh

# 4. ¡Listo!
# https://localhost
```

## 📋 Requisitos del sistema

### Mínimos
- **SO**: Linux, macOS, Windows 10+
- **RAM**: 2GB disponibles
- **Disco**: 5GB libres
- **Docker**: 20.0+
- **Docker Compose**: 1.29+

### Recomendados
- **RAM**: 4GB o más
- **Disco**: 20GB o más (para mensajes y archivos)
- **CPU**: 2 cores o más
- **Conexión**: Estable a internet

## 🔧 Instalación de Docker

### Ubuntu/Debian
```bash
# Actualizar sistema
sudo apt update

# Instalar Docker
curl -fsSL https://get.docker.com | sh

# Agregar usuario al grupo docker
sudo usermod -aG docker $(whoami)

# Aplicar cambios
newgrp docker

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar instalación
docker --version
docker-compose --version
```

### CentOS/RHEL/Fedora
```bash
# Instalar Docker
sudo dnf install -y docker docker-compose

# Iniciar servicio
sudo systemctl start docker
sudo systemctl enable docker

# Agregar usuario al grupo
sudo usermod -aG docker $(whoami)
newgrp docker
```

### macOS
```bash
# Instalar Docker Desktop
# Descargar desde: https://www.docker.com/products/docker-desktop

# O con Homebrew
brew install --cask docker
```

### Windows
```bash
# Instalar Docker Desktop
# Descargar desde: https://www.docker.com/products/docker-desktop

# O con Chocolatey
choco install docker-desktop
```

## 📥 Descarga del proyecto

### Opción 1: Git Clone (recomendado)
```bash
git clone https://github.com/pablety/matrix-universal-docker.git
cd matrix-universal-docker
```

### Opción 2: Descarga ZIP
```bash
# Descargar ZIP desde GitHub
wget https://github.com/pablety/matrix-universal-docker/archive/main.zip
unzip main.zip
cd matrix-universal-docker-main
```

## ⚙️ Configuración inicial

### 1. Configurar variables de entorno
```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Editar configuración
nano .env
```

### 2. Variables importantes
```bash
# Tu dominio o IP
SERVER_NAME=tu-dominio.com

# Contraseña segura para PostgreSQL
POSTGRES_PASSWORD=tu_password_super_secreto

# Permitir registro de usuarios
ENABLE_REGISTRATION=true

# Habilitar federación (opcional)
ENABLE_FEDERATION=false
```

### 3. Crear directorios de datos
```bash
# El script lo hace automáticamente, pero puedes crearlos manualmente
mkdir -p data/{matrix,postgres,ssl,logs}
```

## 🚀 Instalación

### 1. Ejecutar instalador
```bash
# Hacer ejecutable
chmod +x build-and-run.sh

# Ejecutar instalación
./build-and-run.sh
```

### 2. Proceso de instalación
El script hará automáticamente:
1. ✅ Verificar Docker y dependencias
2. ✅ Detectar tu IP local
3. ✅ Crear estructura de directorios
4. ✅ Generar archivo .env
5. ✅ Construir imagen Docker
6. ✅ Iniciar contenedor
7. ✅ Verificar funcionamiento

### 3. Tiempo estimado
- **Primera vez**: 5-10 minutos
- **Reinstalación**: 2-3 minutos

## 👤 Crear primer usuario

### Método 1: Script automático
```bash
./scripts/create-user.sh

# Seguir las instrucciones:
# - Nombre de usuario
# - Contraseña
# - ¿Es administrador? (y/N)
```

### Método 2: Comando directo
```bash
docker exec -it matrix-universal register_matrix_user
```

### Método 3: Comando completo
```bash
docker exec -it matrix-universal sudo -u matrix \
  /opt/matrix/env/bin/register_new_matrix_user \
  -c /opt/matrix/homeserver.yaml \
  -u miusuario \
  -p mipassword \
  --admin \
  --no-config \
  http://localhost:8008
```

## 🌐 Acceso al servidor

### URLs disponibles
- **HTTPS**: `https://localhost` o `https://tu-ip`
- **HTTP**: `http://localhost` o `http://tu-ip`
- **API**: `http://localhost:8008`

### Primer acceso
1. Abrir navegador en `https://localhost`
2. Aceptar certificado autofirmado:
   - Click "Avanzado" o "Advanced"
   - Click "Continuar a localhost (no seguro)"
3. Aparecerá Element Web
4. Iniciar sesión con tu usuario creado

## 🔐 Configuración SSL

### Certificados autofirmados
- Se generan automáticamente
- Válidos por 10 años
- Ubicados en `./data/ssl/`

### Usar certificados propios
```bash
# Copiar tus certificados
cp tu-certificado.crt ./data/ssl/matrix.crt
cp tu-clave-privada.key ./data/ssl/matrix.key

# Reiniciar Nginx
docker-compose restart
```

### Certificados Let's Encrypt
```bash
# Instalar certbot
sudo apt install certbot

# Obtener certificado
sudo certbot certonly --standalone -d tu-dominio.com

# Copiar certificados
sudo cp /etc/letsencrypt/live/tu-dominio.com/fullchain.pem ./data/ssl/matrix.crt
sudo cp /etc/letsencrypt/live/tu-dominio.com/privkey.pem ./data/ssl/matrix.key
sudo chown $(whoami):$(whoami) ./data/ssl/matrix.*

# Reiniciar
docker-compose restart
```

## 🔄 Verificación de instalación

### Verificar servicios
```bash
# Estado de contenedores
docker-compose ps

# Logs del sistema
docker-compose logs -f

# Entrar al contenedor
docker exec -it matrix-universal bash

# Verificar procesos internos
docker exec matrix-universal supervisorctl status
```

### Verificar conectividad
```bash
# API Matrix
curl -k https://localhost/_matrix/client/versions

# Respuesta esperada:
# {"versions":["r0.0.1","r0.1.0","r0.2.0"...]}

# Verificar puertos
sudo netstat -tlnp | grep -E "(80|443|8008)"
```

## 🛠️ Solución de problemas

### Problema: Docker no instalado
```bash
# Instalar Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $(whoami)
newgrp docker
```

### Problema: Permisos de Docker
```bash
# Verificar permisos
docker info

# Si falla, agregar usuario al grupo
sudo usermod -aG docker $(whoami)
newgrp docker
```

### Problema: Puerto ocupado
```bash
# Ver qué usa el puerto 80
sudo lsof -i :80

# Parar servicios conflictivos
sudo systemctl stop apache2 nginx

# Reiniciar Matrix
docker-compose restart
```

### Problema: No se puede conectar
```bash
# Verificar firewall
sudo ufw status

# Abrir puertos
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Verificar IP
hostname -I
```

### Problema: Certificado rechazado
1. Ir a `https://localhost`
2. Click "Avanzado"
3. Click "Continuar a localhost (no seguro)"
4. Element Web debería cargar

## 📱 Configuración de clientes

### Element Desktop
1. Descargar desde [Element.io](https://element.io/get-started)
2. Instalar aplicación
3. Configurar servidor personalizado: `https://tu-ip`
4. Iniciar sesión con tu usuario

### Element Mobile
1. Descargar desde App Store/Google Play
2. Configurar servidor personalizado
3. Iniciar sesión

### Otros clientes Matrix
- **Nheko**: Cliente nativo ligero
- **Fractal**: Cliente GNOME
- **Weechat**: Cliente terminal
- **Riot**: Cliente web alternativo

## 🔧 Configuración avanzada

### Cambiar dominio
```bash
# Editar .env
nano .env

# Cambiar SERVER_NAME
SERVER_NAME=mi-dominio.com

# Reconstruir
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Habilitar federación
```bash
# Editar .env
ENABLE_FEDERATION=true

# Reconstruir
docker-compose restart
```

### Configurar límites de recursos
```bash
# Editar docker-compose.yml
nano docker-compose.yml

# Agregar limits
deploy:
  resources:
    limits:
      memory: 4G
      cpus: '2.0'
```

## 📊 Monitoreo

### Logs en tiempo real
```bash
# Todos los logs
docker-compose logs -f

# Solo Matrix
docker-compose logs -f matrix-universal

# Solo errores
docker-compose logs -f | grep ERROR
```

### Estadísticas de uso
```bash
# Entrar al contenedor
docker exec -it matrix-universal bash

# Ver usuarios
sudo -u postgres psql -d synapse -c "SELECT COUNT(*) FROM users;"

# Ver salas
sudo -u postgres psql -d synapse -c "SELECT COUNT(*) FROM rooms;"
```

## 💾 Backup y restauración

### Crear backup
```bash
# Backup automático
./scripts/backup.sh

# Backup manual
docker exec matrix-universal sudo -u postgres pg_dump synapse > backup.sql
```

### Restaurar backup
```bash
# Parar contenedor
docker-compose down

# Restaurar datos
tar -xzf backup.tar.gz

# Iniciar contenedor
docker-compose up -d
```

## 🔄 Actualización

### Actualizar Matrix
```bash
# Actualizar imágenes
docker-compose pull

# Reconstruir
docker-compose build --no-cache

# Reiniciar
docker-compose up -d
```

### Actualizar sistema
```bash
# Actualizar Docker
sudo apt update && sudo apt upgrade docker-ce docker-compose

# Verificar versiones
docker --version
docker-compose --version
```

## 🎉 ¡Instalación completada!

Tu servidor Matrix Universal está listo:

- 🌐 **Acceso**: `https://localhost`
- 👤 **Usuarios**: Crear con `./scripts/create-user.sh`
- 💾 **Datos**: Guardados en `./data/`
- 🔧 **Logs**: `docker-compose logs -f`
- 📖 **Ayuda**: [docs/USAGE.md](./USAGE.md)

¡Disfruta tu servidor Matrix! 🚀