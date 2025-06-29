# 📖 Manual de Uso - Matrix Universal Docker

Guía completa para usar tu servidor Matrix Universal después de la instalación.

## 🎯 Acceso inicial

### 1. Abrir Element Web
```bash
# Abrir navegador en:
https://localhost
# O tu IP:
https://tu-ip
```

### 2. Aceptar certificado SSL
1. Click "Avanzado" o "Advanced"
2. Click "Continuar a localhost (no seguro)"
3. Element Web se cargará

### 3. Iniciar sesión
1. Usar el usuario creado durante la instalación
2. Si no tienes usuario, crear uno:
   ```bash
   ./scripts/create-user.sh
   ```

## 👤 Gestión de usuarios

### Crear nuevos usuarios

#### Método 1: Script automático (recomendado)
```bash
./scripts/create-user.sh

# Seguir instrucciones:
# - Nombre de usuario: alice
# - Contraseña: ********
# - ¿Es administrador? (y/N): n
```

#### Método 2: Comando directo
```bash
docker exec -it matrix-universal register_matrix_user
```

#### Método 3: Comando completo
```bash
docker exec -it matrix-universal sudo -u matrix \
  /opt/matrix/env/bin/register_new_matrix_user \
  -c /opt/matrix/homeserver.yaml \
  -u nombre_usuario \
  -p contraseña_segura \
  --no-config \
  http://localhost:8008
```

### Crear usuario administrador
```bash
./scripts/create-user.sh admin password123 y
```

### Listar usuarios existentes
```bash
docker exec matrix-universal sudo -u postgres psql -d synapse -c "
SELECT name, admin, deactivated, creation_ts 
FROM users 
ORDER BY creation_ts DESC;
"
```

### Desactivar usuario
```bash
docker exec matrix-universal sudo -u postgres psql -d synapse -c "
UPDATE users SET deactivated = 1 WHERE name = '@usuario:tu-servidor';
"
```

## 🏠 Gestión de salas

### Crear salas

#### Desde Element Web
1. Click en "+" junto a "Rooms"
2. Click "Create room"
3. Configurar:
   - **Name**: Nombre de la sala
   - **Topic**: Descripción
   - **Visibility**: Pública o privada
   - **Encryption**: Activar cifrado

#### Tipos de salas
- **Pública**: Cualquiera puede unirse
- **Privada**: Solo por invitación
- **Cifrada**: Mensajes cifrados de extremo a extremo

### Invitar usuarios a salas
1. Entrar a la sala
2. Click en "Room info" (i)
3. Click "Invite"
4. Escribir: `@usuario:tu-servidor`

### Configurar permisos
1. Room info → Settings → Roles & Permissions
2. Configurar roles:
   - **Admin**: Control total
   - **Moderator**: Moderar mensajes
   - **Default**: Usuario normal

## 💬 Mensajería

### Tipos de mensajes
- **Texto**: Mensajes normales
- **Markdown**: Formato con `**negrita**`, `*cursiva*`
- **HTML**: Formato avanzado
- **Código**: Bloques de código con ```
- **Emojis**: :smile: :heart: :thumbsup:

### Comandos de sala
```
/me acción          # Mensaje de acción
/topic nuevo tema   # Cambiar tema de sala
/invite @usuario    # Invitar usuario
/kick @usuario      # Expulsar usuario
/ban @usuario       # Banear usuario
/unban @usuario     # Desbanear usuario
/op @usuario        # Dar permisos de operador
/deop @usuario      # Quitar permisos de operador
```

### Menciones
```
@usuario         # Mencionar usuario específico
@room           # Mencionar a toda la sala
```

## 📁 Compartir archivos

### Subir archivos
1. Click en clip 📎 en Element Web
2. Seleccionar archivo
3. Opcional: Agregar descripción
4. Send

### Límites de archivos
- **Tamaño máximo**: 50MB (configurable)
- **Tipos permitidos**: Todos
- **Almacenamiento**: En el servidor Matrix

### Configurar límites
```bash
# Editar .env
nano .env

# Cambiar límite
MAX_UPLOAD_SIZE=100  # MB

# Reiniciar
docker-compose restart
```

## 🔐 Cifrado de extremo a extremo

### Activar cifrado en salas
1. Room Settings → Security & Privacy
2. Enable "Encrypt to verified users and trusted devices only"
3. Confirmar activación

### Verificar dispositivos
1. User Settings → Security & Privacy
2. Verificar dispositivos de otros usuarios
3. Confirmar claves de verificación

### Copia de seguridad de claves
1. User Settings → Security & Privacy
2. "Set up Secure Backup"
3. Guardar clave de recuperación en lugar seguro

## 📞 Llamadas de voz y video

### Llamadas 1-a-1
1. Abrir chat privado
2. Click en teléfono 📞 (voz) o cámara 📹 (video)
3. Esperar que el otro usuario responda

### Llamadas grupales
1. En una sala cifrada
2. Click en "Start voice call" o "Start video call"
3. Otros usuarios pueden unirse

### Configuración de llamadas
1. User Settings → Voice & Video
2. Configurar:
   - **Camera**: Seleccionar cámara
   - **Microphone**: Seleccionar micrófono
   - **Speaker**: Seleccionar altavoces

## 🔔 Notificaciones

### Configurar notificaciones
1. User Settings → Notifications
2. Configurar por tipo:
   - **Mentions**: Cuando te mencionan
   - **Keywords**: Palabras clave específicas
   - **Rooms**: Notificaciones por sala

### Notificaciones por sala
1. Room Settings → Notifications
2. Opciones:
   - **All messages**: Todos los mensajes
   - **Mentions only**: Solo menciones
   - **Mute**: Sin notificaciones

## 🎨 Personalización

### Cambiar tema
1. User Settings → Appearance
2. Seleccionar tema:
   - **Light**: Tema claro
   - **Dark**: Tema oscuro
   - **Auto**: Automático según sistema

### Configurar idioma
1. User Settings → General
2. Language: Seleccionar idioma
3. Restart Element Web

### Avatar y perfil
1. User Settings → General
2. Click en avatar para cambiar foto
3. Display name: Cambiar nombre mostrado

## 🔧 Administración del servidor

### Ver estadísticas
```bash
# Usuarios registrados
docker exec matrix-universal sudo -u postgres psql -d synapse -c "
SELECT COUNT(*) as usuarios_total FROM users;
"

# Salas creadas
docker exec matrix-universal sudo -u postgres psql -d synapse -c "
SELECT COUNT(*) as salas_total FROM rooms;
"

# Mensajes enviados
docker exec matrix-universal sudo -u postgres psql -d synapse -c "
SELECT COUNT(*) as mensajes_total FROM events;
"
```

### Configurar registro de usuarios
```bash
# Habilitar registro público
nano .env
ENABLE_REGISTRATION=true

# Deshabilitar registro público
nano .env
ENABLE_REGISTRATION=false

# Reiniciar
docker-compose restart
```

### Configurar federación
```bash
# Habilitar federación
nano .env
ENABLE_FEDERATION=true

# Configurar dominio público
SERVER_NAME=mi-dominio.com

# Reiniciar
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## 📊 Monitoreo y logs

### Ver logs en tiempo real
```bash
# Todos los servicios
docker-compose logs -f

# Solo Matrix Synapse
docker-compose logs -f matrix-universal

# Solo errores
docker-compose logs -f | grep ERROR

# Logs específicos
docker exec matrix-universal tail -f /var/log/matrix/homeserver.log
```

### Verificar estado de servicios
```bash
# Estado de contenedores
docker-compose ps

# Procesos internos
docker exec matrix-universal supervisorctl status

# Recursos utilizados
docker stats matrix-universal
```

### Información del sistema
```bash
# Espacio en disco
docker exec matrix-universal df -h

# Memoria RAM
docker exec matrix-universal free -h

# Procesos activos
docker exec matrix-universal htop
```

## 💾 Backup y mantenimiento

### Backup automático
```bash
# Crear backup completo
./scripts/backup.sh

# Ubicación: ./backups/matrix_backup_YYYYMMDD_HHMMSS.tar.gz
```

### Mantenimiento automático
```bash
# Ejecutar mantenimiento
./scripts/maintenance.sh

# Incluye:
# - Limpieza de logs antiguos
# - Optimización de base de datos
# - Verificación de servicios
# - Estadísticas de uso
```

### Backup manual
```bash
# Backup base de datos
docker exec matrix-universal sudo -u postgres pg_dump synapse > backup_$(date +%Y%m%d).sql

# Backup archivos Matrix
docker exec matrix-universal tar -czf /tmp/matrix_backup.tar.gz -C /opt/matrix data
docker cp matrix-universal:/tmp/matrix_backup.tar.gz ./
```

## 🔄 Actualización

### Actualizar Matrix Synapse
```bash
# Actualizar imágenes
docker-compose pull

# Reconstruir imagen
docker-compose build --no-cache

# Reiniciar servicios
docker-compose up -d

# Verificar actualización
docker exec matrix-universal sudo -u matrix /opt/matrix/env/bin/pip list | grep matrix-synapse
```

### Actualizar Element Web
```bash
# Reconstruir imagen (incluye Element Web más reciente)
docker-compose build --no-cache matrix-universal

# Reiniciar
docker-compose up -d
```

## 🌐 Acceso remoto

### Configurar dominio propio
```bash
# 1. Configurar DNS
# A record: matrix.tu-dominio.com → tu-ip-publica

# 2. Configurar servidor
nano .env
SERVER_NAME=matrix.tu-dominio.com

# 3. Reconstruir
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### SSL con Let's Encrypt
```bash
# 1. Instalar certbot
sudo apt install certbot

# 2. Obtener certificado
sudo certbot certonly --standalone -d matrix.tu-dominio.com

# 3. Copiar certificados
sudo cp /etc/letsencrypt/live/matrix.tu-dominio.com/fullchain.pem ./data/ssl/matrix.crt
sudo cp /etc/letsencrypt/live/matrix.tu-dominio.com/privkey.pem ./data/ssl/matrix.key
sudo chown $(whoami):$(whoami) ./data/ssl/matrix.*

# 4. Reiniciar
docker-compose restart
```

### Configurar puerto personalizado
```bash
# Editar docker-compose.yml
nano docker-compose.yml

# Cambiar puertos
ports:
  - "8080:80"    # HTTP en puerto 8080
  - "8443:443"   # HTTPS en puerto 8443

# Reiniciar
docker-compose up -d

# Acceso: https://localhost:8443
```

## 📱 Clientes móviles

### Element Mobile
1. **Descargar**: App Store o Google Play
2. **Configurar**: Servidor personalizado
3. **URL**: `https://tu-ip` o `https://tu-dominio.com`
4. **Iniciar sesión**: Con tu usuario

### Otros clientes Matrix
- **FluffyChat**: Cliente moderno y fácil
- **SchildiChat**: Fork de Element con mejoras
- **Nheko**: Cliente nativo ligero

## 🔧 Solución de problemas comunes

### No puedo acceder a Element Web
1. Verificar que el contenedor esté corriendo:
   ```bash
   docker-compose ps
   ```
2. Verificar logs:
   ```bash
   docker-compose logs -f
   ```
3. Verificar puertos:
   ```bash
   sudo netstat -tlnp | grep -E "(80|443)"
   ```

### Error de certificado SSL
1. Aceptar certificado autofirmado en navegador
2. O usar HTTP temporalmente: `http://localhost`
3. O instalar certificado válido

### No puedo crear usuarios
1. Verificar que el registro esté habilitado:
   ```bash
   grep ENABLE_REGISTRATION .env
   ```
2. Verificar que Matrix esté funcionando:
   ```bash
   curl -k https://localhost/_matrix/client/versions
   ```

### Problemas de rendimiento
1. Verificar recursos:
   ```bash
   docker stats matrix-universal
   ```
2. Aumentar límites en docker-compose.yml
3. Optimizar base de datos:
   ```bash
   ./scripts/maintenance.sh
   ```

## 📚 Recursos adicionales

### Documentación Matrix
- [Matrix.org](https://matrix.org/) - Sitio oficial
- [Matrix Spec](https://spec.matrix.org/) - Especificación técnica
- [Element Help](https://element.io/help) - Ayuda de Element

### Comunidades Matrix
- Matrix HQ: `#matrix:matrix.org`
- Element Web: `#element-web:matrix.org`
- Synapse: `#synapse:matrix.org`

### Herramientas útiles
- [Matrix Federation Tester](https://federationtester.matrix.org/)
- [Matrix Client Comparison](https://matrix.org/clients/)
- [Matrix Bots](https://matrix.org/bots/)

## 🎉 ¡Disfruta tu servidor Matrix!

Ya tienes todo lo necesario para usar tu servidor Matrix Universal:

- 💬 **Chat**: Mensajes individuales y grupales
- 🔐 **Seguridad**: Cifrado de extremo a extremo
- 📞 **Llamadas**: Voz y video integradas
- 📁 **Archivos**: Compartir documentos y medios
- 🔧 **Administración**: Control total del servidor

¡Invita a tus amigos y familiares a unirse a tu servidor Matrix! 🚀