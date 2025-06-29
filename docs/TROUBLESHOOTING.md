# 🔧 Solución de Problemas - Matrix Universal Docker

Guía completa para resolver problemas comunes con tu servidor Matrix Universal.

## 🚨 Problemas durante la instalación

### Docker no está instalado
```
Error: docker: command not found
```

**Solución:**
```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $(whoami)
newgrp docker

# CentOS/RHEL
sudo dnf install -y docker docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $(whoami)

# Verificar
docker --version
```

### Permisos insuficientes de Docker
```
Error: permission denied while trying to connect to Docker daemon
```

**Solución:**
```bash
# Agregar usuario al grupo docker
sudo usermod -aG docker $(whoami)

# Aplicar cambios
newgrp docker

# O reiniciar sesión
exit
# Volver a conectar
```

### Puerto ocupado
```
Error: port is already allocated
```

**Solución:**
```bash
# Ver qué proceso usa el puerto
sudo lsof -i :80
sudo lsof -i :443

# Parar servicios conflictivos
sudo systemctl stop apache2
sudo systemctl stop nginx

# O cambiar puertos en docker-compose.yml
nano docker-compose.yml
# Cambiar "80:80" por "8080:80"
```

### Espacio insuficiente en disco
```
Error: no space left on device
```

**Solución:**
```bash
# Verificar espacio
df -h

# Limpiar Docker
docker system prune -a -f

# Limpiar logs
sudo journalctl --vacuum-time=7d

# Mover datos a otra partición
sudo mv ./data /ruta/con/mas/espacio/
ln -s /ruta/con/mas/espacio/data ./data
```

## 🌐 Problemas de conectividad

### No puedo acceder a Element Web
```
Error: Este sitio no se puede alcanzar
```

**Diagnóstico:**
```bash
# 1. Verificar que el contenedor esté corriendo
docker-compose ps

# 2. Verificar logs
docker-compose logs -f matrix-universal

# 3. Verificar puertos
sudo netstat -tlnp | grep -E "(80|443|8008)"

# 4. Probar conectividad local
curl -k https://localhost/_matrix/client/versions
```

**Soluciones:**
```bash
# Si el contenedor no está corriendo
docker-compose up -d

# Si hay errores en logs
docker-compose restart

# Si no hay puertos abiertos
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### Error de certificado SSL
```
Error: NET::ERR_CERT_AUTHORITY_INVALID
```

**Solución:**
```bash
# Opción 1: Aceptar certificado en navegador
# 1. Click "Avanzado" o "Advanced"
# 2. Click "Continuar a localhost (no seguro)"

# Opción 2: Usar HTTP temporalmente
# Acceder a: http://localhost

# Opción 3: Instalar certificado válido
sudo certbot certonly --standalone -d tu-dominio.com
sudo cp /etc/letsencrypt/live/tu-dominio.com/fullchain.pem ./data/ssl/matrix.crt
sudo cp /etc/letsencrypt/live/tu-dominio.com/privkey.pem ./data/ssl/matrix.key
docker-compose restart
```

### Matrix API no responde
```
Error: Connection refused
```

**Diagnóstico:**
```bash
# Verificar Matrix Synapse
docker exec matrix-universal supervisorctl status matrix-synapse

# Ver logs específicos
docker exec matrix-universal tail -f /var/log/matrix/homeserver.log

# Probar API directamente
curl http://localhost:8008/_matrix/client/versions
```

**Soluciones:**
```bash
# Reiniciar Matrix
docker exec matrix-universal supervisorctl restart matrix-synapse

# Verificar configuración
docker exec matrix-universal cat /opt/matrix/homeserver.yaml | grep -A 10 "listeners"

# Reiniciar contenedor completo
docker-compose restart
```

## 🗄️ Problemas de base de datos

### PostgreSQL no inicia
```
Error: could not connect to server
```

**Diagnóstico:**
```bash
# Verificar PostgreSQL
docker exec matrix-universal supervisorctl status postgresql

# Ver logs
docker exec matrix-universal tail -f /var/log/postgresql.log

# Verificar conectividad
docker exec matrix-universal sudo -u postgres psql -c "SELECT version();"
```

**Soluciones:**
```bash
# Reiniciar PostgreSQL
docker exec matrix-universal supervisorctl restart postgresql

# Verificar espacio en disco
docker exec matrix-universal df -h

# Reiniciar contenedor completo
docker-compose restart
```

### Error de conexión a base de datos
```
Error: psycopg2.OperationalError: could not connect to server
```

**Solución:**
```bash
# Verificar configuración de conexión
docker exec matrix-universal grep -A 10 "database:" /opt/matrix/homeserver.yaml

# Verificar usuario y contraseña
docker exec matrix-universal sudo -u postgres psql -c "\du"

# Recrear usuario si es necesario
docker exec matrix-universal sudo -u postgres psql -c "
ALTER USER synapse_user WITH PASSWORD 'nueva_password';
"

# Actualizar configuración
nano .env
# Cambiar POSTGRES_PASSWORD
docker-compose restart
```

### Base de datos corrupta
```
Error: database is corrupted
```

**Solución:**
```bash
# 1. Crear backup antes de reparar
./scripts/backup.sh

# 2. Intentar reparación automática
docker exec matrix-universal sudo -u postgres psql -d synapse -c "
REINDEX DATABASE synapse;
VACUUM FULL;
"

# 3. Si falla, restaurar desde backup
docker-compose down
# Restaurar backup siguiendo instrucciones en backup_info.txt
docker-compose up -d
```

## 👤 Problemas con usuarios

### No puedo crear usuarios
```
Error: Registration is disabled
```

**Solución:**
```bash
# Verificar configuración de registro
grep ENABLE_REGISTRATION .env

# Habilitar registro si está deshabilitado
nano .env
ENABLE_REGISTRATION=true

# Reiniciar
docker-compose restart

# Verificar configuración en Matrix
docker exec matrix-universal grep "enable_registration" /opt/matrix/homeserver.yaml
```

### Error al registrar usuario
```
Error: User already exists
```

**Soluciones:**
```bash
# Verificar usuarios existentes
docker exec matrix-universal sudo -u postgres psql -d synapse -c "
SELECT name FROM users ORDER BY creation_ts;
"

# Usar nombre diferente
./scripts/create-user.sh nuevo_usuario

# O desactivar usuario existente
docker exec matrix-universal sudo -u postgres psql -d synapse -c "
UPDATE users SET deactivated = 1 WHERE name = '@usuario_existente:tu-servidor';
"
```

### No puedo iniciar sesión
```
Error: Invalid username or password
```

**Diagnóstico:**
```bash
# Verificar que el usuario existe
docker exec matrix-universal sudo -u postgres psql -d synapse -c "
SELECT name, deactivated FROM users WHERE name = '@tu_usuario:tu-servidor';
"

# Verificar logs de autenticación
docker exec matrix-universal grep "login" /var/log/matrix/homeserver.log | tail -10
```

**Soluciones:**
```bash
# Cambiar contraseña
docker exec matrix-universal sudo -u matrix \
  /opt/matrix/env/bin/hash_password -p nueva_password

# Actualizar en base de datos (requiere hash)
docker exec matrix-universal sudo -u postgres psql -d synapse -c "
UPDATE users SET password_hash = 'HASH_DE_ARRIBA' WHERE name = '@tu_usuario:tu-servidor';
"

# O crear usuario nuevo
./scripts/create-user.sh
```

## 🔐 Problemas de cifrado

### Error de claves de cifrado
```
Error: Unable to decrypt message
```

**Solución:**
```bash
# En Element Web:
# 1. Settings → Security & Privacy
# 2. "Set up Secure Backup"
# 3. Verificar dispositivos de otros usuarios

# Si persiste, reset de claves
# 1. Settings → Security & Privacy
# 2. "Reset cross-signing keys"
# 3. Verificar dispositivos nuevamente
```

### Dispositivos no verificados
```
Warning: Unverified devices in this room
```

**Solución:**
```bash
# Para cada usuario:
# 1. Click en su nombre
# 2. Verificar dispositivos
# 3. Confirmar códigos de verificación

# O deshabilitar verificación estricta
# Room Settings → Security & Privacy
# Desactivar "Only allow verified devices"
```

## 🔊 Problemas de llamadas

### Llamadas no funcionan
```
Error: Failed to start call
```

**Diagnóstico:**
```bash
# Verificar configuración de llamadas
# En Element Web: Settings → Voice & Video

# Verificar permisos del navegador
# Permitir acceso a micrófono y cámara
```

**Soluciones:**
```bash
# Verificar WebRTC
# En navegador: chrome://webrtc-internals/

# Configurar TURN server (para llamadas externas)
docker exec matrix-universal nano /opt/matrix/homeserver.yaml
# Agregar configuración TURN

# Reiniciar Nginx
docker-compose restart
```

### No hay audio/video
```
Error: No media tracks
```

**Solución:**
```bash
# Verificar dispositivos
# Settings → Voice & Video → Test microphone/camera

# Verificar permisos del navegador
# Chrome: chrome://settings/content/camera
# Firefox: about:preferences#privacy

# Reiniciar navegador
# Limpiar caché y cookies
```

## 📁 Problemas con archivos

### No puedo subir archivos
```
Error: File too large
```

**Solución:**
```bash
# Verificar límite actual
grep MAX_UPLOAD_SIZE .env

# Aumentar límite
nano .env
MAX_UPLOAD_SIZE=100  # MB

# Reiniciar
docker-compose restart

# Verificar en Matrix
docker exec matrix-universal grep "max_upload_size" /opt/matrix/homeserver.yaml
```

### Archivos no se descargan
```
Error: Failed to download file
```

**Diagnóstico:**
```bash
# Verificar almacenamiento de archivos
docker exec matrix-universal ls -la /opt/matrix/data/media_store/

# Verificar espacio en disco
docker exec matrix-universal df -h

# Verificar permisos
docker exec matrix-universal ls -la /opt/matrix/data/
```

**Soluciones:**
```bash
# Corregir permisos
docker exec matrix-universal chown -R matrix:matrix /opt/matrix/data/

# Limpiar archivos antiguos
docker exec matrix-universal find /opt/matrix/data/media_store/ -type f -mtime +365 -delete

# Reiniciar Matrix
docker-compose restart
```

## 🔧 Problemas de rendimiento

### Servidor muy lento
```
Síntoma: Element Web carga lentamente
```

**Diagnóstico:**
```bash
# Verificar recursos
docker stats matrix-universal

# Verificar carga del sistema
docker exec matrix-universal htop

# Verificar logs de rendimiento
docker exec matrix-universal grep "slow" /var/log/matrix/homeserver.log
```

**Soluciones:**
```bash
# Aumentar recursos en docker-compose.yml
nano docker-compose.yml
# Cambiar limits de memoria y CPU

# Optimizar base de datos
./scripts/maintenance.sh

# Ajustar configuración de caché
docker exec matrix-universal nano /opt/matrix/homeserver.yaml
# Aumentar cache_factor

# Reiniciar
docker-compose restart
```

### Mucho uso de memoria
```
Síntoma: El contenedor usa demasiada RAM
```

**Solución:**
```bash
# Verificar uso actual
docker stats matrix-universal

# Reducir caché de Matrix
docker exec matrix-universal nano /opt/matrix/homeserver.yaml
# Reducir global_factor en caches

# Limpiar caché
docker exec matrix-universal supervisorctl restart matrix-synapse

# Configurar límites más estrictos
nano docker-compose.yml
# Reducir memory limit
```

## 🔄 Problemas de actualización

### Error al actualizar
```
Error: Failed to pull image
```

**Solución:**
```bash
# Limpiar imágenes anteriores
docker system prune -a -f

# Reconstruir imagen
docker-compose build --no-cache

# Reiniciar servicios
docker-compose up -d
```

### Configuración incompatible
```
Error: Invalid configuration after update
```

**Solución:**
```bash
# Crear backup de configuración
cp /opt/matrix/homeserver.yaml /opt/matrix/homeserver.yaml.backup

# Regenerar configuración base
docker exec matrix-universal sudo -u matrix bash -c "
cd /opt/matrix
source env/bin/activate
python -m synapse.app.homeserver \
  --server-name=tu-servidor \
  --config-path=/opt/matrix/homeserver.yaml.new \
  --generate-config \
  --report-stats=no
"

# Migrar configuración personalizada manualmente
# Comparar archivos y aplicar cambios necesarios
```

## 🆘 Comandos de emergencia

### Reinicio completo
```bash
# Parar todo
docker-compose down

# Limpiar contenedores
docker system prune -f

# Reconstruir desde cero
docker-compose build --no-cache

# Iniciar
docker-compose up -d
```

### Restaurar desde backup
```bash
# Parar servicios
docker-compose down

# Restaurar datos
tar -xzf backup.tar.gz -C ./

# Restaurar base de datos
docker-compose up -d
docker exec matrix-universal sudo -u postgres psql -d synapse < backup.sql

# Verificar funcionamiento
docker-compose logs -f
```

### Reset completo (¡CUIDADO!)
```bash
# ⚠️ ESTO BORRA TODOS LOS DATOS ⚠️

# Crear backup primero
./scripts/backup.sh

# Parar y eliminar contenedores
docker-compose down
docker system prune -a -f

# Eliminar datos
rm -rf data/

# Reinstalar desde cero
./build-and-run.sh
```

## 📞 Obtener ayuda

### Logs de diagnóstico
```bash
# Crear archivo de diagnóstico completo
echo "=== DIAGNÓSTICO MATRIX UNIVERSAL DOCKER ===" > diagnostico.txt
echo "Fecha: $(date)" >> diagnostico.txt
echo "Sistema: $(uname -a)" >> diagnostico.txt
echo "Docker: $(docker --version)" >> diagnostico.txt
echo "" >> diagnostico.txt

echo "=== ESTADO DE CONTENEDORES ===" >> diagnostico.txt
docker-compose ps >> diagnostico.txt
echo "" >> diagnostico.txt

echo "=== LOGS RECIENTES ===" >> diagnostico.txt
docker-compose logs --tail=50 >> diagnostico.txt
echo "" >> diagnostico.txt

echo "=== CONFIGURACIÓN ===" >> diagnostico.txt
cat .env >> diagnostico.txt

# Enviar diagnostico.txt al obtener ayuda
```

### Recursos de ayuda
- **Documentación**: [docs/](./docs/)
- **Issues GitHub**: Crear issue con logs de diagnóstico
- **Comunidad Matrix**: `#matrix:matrix.org`
- **Element Help**: https://element.io/help

### Información útil para reportar problemas
```bash
# Incluir siempre esta información:
echo "Sistema: $(uname -a)"
echo "Docker: $(docker --version)"
echo "Compose: $(docker-compose --version)"
echo "Versión Matrix: $(docker exec matrix-universal sudo -u matrix /opt/matrix/env/bin/pip list | grep matrix-synapse)"
echo "IP del servidor: $(hostname -I)"
echo "Fecha del problema: $(date)"
```

## 🎯 Prevención de problemas

### Monitoreo regular
```bash
# Ejecutar mantenimiento semanal
./scripts/maintenance.sh

# Verificar espacio en disco
df -h

# Verificar estado de servicios
docker-compose ps
```

### Backups automáticos
```bash
# Crear script de backup automático
echo '#!/bin/bash' > /usr/local/bin/matrix-backup-daily
echo 'cd /ruta/a/matrix-universal-docker' >> /usr/local/bin/matrix-backup-daily
echo './scripts/backup.sh' >> /usr/local/bin/matrix-backup-daily
chmod +x /usr/local/bin/matrix-backup-daily

# Agregar a crontab
crontab -e
# Agregar línea:
# 0 2 * * * /usr/local/bin/matrix-backup-daily
```

### Actualizaciones regulares
```bash
# Actualizar semanalmente
docker-compose pull
docker-compose build --no-cache
docker-compose up -d

# Verificar funcionamiento
curl -k https://localhost/_matrix/client/versions
```

---

## 🎉 ¡Problema resuelto!

Si sigues teniendo problemas después de probar estas soluciones:

1. 📝 Crear archivo de diagnóstico completo
2. 🔍 Revisar logs detalladamente
3. 💬 Crear issue en GitHub con toda la información
4. 🆘 Contactar la comunidad Matrix

¡Tu servidor Matrix Universal volverá a funcionar perfectamente! 🚀