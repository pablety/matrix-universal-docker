# Matrix Universal Docker 🚀

**Servidor Matrix completo que funciona en cualquier equipo con Docker**

[![Docker](https://img.shields.io/badge/Docker-Compatible-blue.svg)](https://www.docker.com/)
[![Matrix](https://img.shields.io/badge/Matrix-Synapse-green.svg)](https://matrix.org/)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-blue.svg)](https://www.postgresql.org/)
[![Element](https://img.shields.io/badge/Client-Element-lightgreen.svg)](https://element.io/)

## 🎯 Características

- ✅ **Funciona en cualquier equipo** con Docker
- ✅ **Instalación en 5 minutos**
- ✅ **Datos persistentes** automáticamente
- ✅ **HTTPS incluido** con certificados SSL
- ✅ **PostgreSQL integrado** para máximo rendimiento
- ✅ **Element Web** incluido para acceso inmediato
- ✅ **Backup automático** de todos los datos
- ✅ **Configuración sencilla** con variables de entorno

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

## 📞 Soporte

### Documentación adicional

- 📖 [Guía de instalación detallada](./docs/INSTALL.md)
- 📖 [Manual de uso](./docs/USAGE.md)
- 📖 [Solución de problemas](./docs/TROUBLESHOOTING.md)

### Recursos útiles

- [Matrix.org](https://matrix.org/) - Documentación oficial
- [Element.io](https://element.io/) - Cliente oficial
- [Docker Hub](https://hub.docker.com/) - Imágenes Docker

## 📝 Changelog

### v1.0 (2025-06-29)
- ✅ Versión inicial
- ✅ PostgreSQL integrado
- ✅ Element Web incluido
- ✅ HTTPS automático
- ✅ Scripts de utilidad
- ✅ Backup automático

## 📄 Licencia

MIT License - Libre para uso personal y comercial

## 👨‍💻 Autor

Creado por **pablety** - 2025-06-29

---

**🎉 ¡Disfruta tu servidor Matrix Universal!**