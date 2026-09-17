# DOLIBARR DOCKER STACK

Stack completo de Dolibarr ERP/CRM sobre Docker, con Nginx, MariaDB, Traefik (opcional) y sistema de respaldos automatizado.

Autor: [MTIE Miguel Martínez](https://github.com/djmai)

---

## 📋 TABLA DE CONTENIDOS

1. [Características](#1-características)
2. [Requisitos](#2-requisitos)
3. [Estructura del Proyecto](#3-estructura-del-proyecto)
4. [Instalación Rápida](#4-instalación-rápida)
5. [Configuración](#5-configuración)
6. [Uso](#6-uso)
7. [Respaldos](#7-respaldos)
8. [Traefik (Dominios Locales y SSL)](#8-traefik-dominios-locales-y-ssl)
9. [Comandos del Makefile](#9-comandos-del-makefile)
10. [Solución de Problemas](#10-solución-de-problemas)
11. [Licencia](#11-licencia)
12. [Créditos](#créditos)
13. [Autor](#autor)

---

## 1. CARACTERÍSTICAS

- **Dockerizado**: Todo el stack corre en contenedores.
- **Nginx**: Servidor web optimizado para Dolibarr.
- **MariaDB**: Base de datos robusta y compatible.
- **Traefik**: Proxy inverso con soporte para dominios locales y SSL.
- **Respaldos automatizados**: Rotación de 3 respaldos por nomenclatura.
- **Actualizaciones Git**: Instalación y actualización de Dolibarr vía Git.
- **Makefile**: Comandos simplificados para todas las operaciones.
- **Kool**: Alternativa a Make para quienes prefieren `kool <comando>`.
- **SSL local**: Certificados autofirmados para desarrollo.

---

## 2. REQUISITOS

- Windows 11 con WSL2 habilitado (o Linux/macOS nativo)
- Docker Desktop (o Docker Engine + Docker Compose v2)
- Debian (u otra distro) dentro de WSL2
- Make y Git instalados en WSL:

```bash
sudo apt update && sudo apt install -y make git
```

- Opcional: `column` para el comando `make help`:

```bash
sudo apt install -y bsdmainutils
```

---

## 3. ESTRUCTURA DEL PROYECTO

```text
doli-docker/
├── app/                          Código fuente de Dolibarr (htdocs, custom, documents)
│   └── README.md
├── backups/                      Respaldos de la carpeta app/
│   └── README.md
├── db/                           Respaldos de base de datos (herramienta externa)
│   └── README.md
├── docker/                       Configuración de la imagen Docker
│   ├── nginx/
│   │   └── nginx.conf
│   ├── php/
│   │   ├── php.ini
│   │   └── xdebug.ini
│   └── Dockerfile
├── scripts/                      Scripts auxiliares
│   ├── rotate-backups.sh          Rotación de respaldos por nomenclatura
│   └── README.md
├── traefik/                      Configuración de Traefik
│   ├── configs/                  Configuración estática
│   │   ├── traefik-http.yml
│   │   └── traefik-ssl.yml
│   ├── certs/                    Certificados autofirmados
│   │   ├── local.crt
│   │   ├── local.key
│   │   └── README.md
│   ├── dynamic/                  Configuración dinámica (middlewares, TLS)
│   │   ├── dashboard.yml
│   │   ├── middlewares.yml
│   │   ├── tls.yml
│   │   └── README.md
│   ├── letsencrypt/              Persistencia de ACME (Let's Encrypt)
│   │   ├── acme.json
│   │   └── README.md
│   └── README.md
├── .env                          Variables de entorno (NO versionado)
├── .env.example                  Plantilla de variables (versionado)
├── .gitignore
├── docker-compose.dev.yml        Stack de desarrollo (sin Traefik)
├── docker-compose.traefik.yml    Stack con Traefik (HTTP)
├── docker-compose.traefik-ssl.yml Stack con Traefik (HTTPS)
├── kool.yml                      Comandos de Kool (wrapper del Makefile)
├── Makefile                      Comandos del proyecto
└── README.md                     Este archivo
```

---

## 4. INSTALACIÓN RÁPIDA

```bash
# 1. Clonar el repositorio
git clone <url-del-repo> doli-docker
cd doli-docker

# 2. Crear el archivo .env desde la plantilla
make env

# 3. Editar .env con tus credenciales
nano .env

# 4. Instalar Dolibarr (última versión estable vía Git)
make install-doli

# 5. Levantar el stack (elige una opción)
make dev-start       # Desarrollo simple (sin Traefik)
make traefik-start   # Con Traefik (HTTP)
make traefik-ssl-start # Con Traefik (HTTPS)
```

Accede a Dolibarr en:

- **Sin Traefik**: `http://localhost:8080`
- **Con Traefik**: `http://dolibarr.local` *(requiere archivo hosts)*
- **Con Traefik SSL**: `https://dolibarr.local` *(certificado autofirmado)*

---

## 5. CONFIGURACIÓN

Todas las variables se centralizan en el archivo `.env`.
Consulta `.env.example` para ver la lista completa con comentarios.

**Variables principales:**

| Variable | Descripción | Valor por defecto |
| :--- | :--- | :--- |
| `APP_NAME` | Nombre del contenedor de la app | `dolibarr` |
| `APP_PORT` | Puerto del host para la app | `8080` |
| `APP_FOLDER` | Carpeta local del código | `app` |
| `APP_DOMAIN` | Dominio local para Traefik | `dolibarr.local` |
| `DB_NAME` | Nombre del contenedor de MariaDB | `mariadb` |
| `MARIA_*` | Credenciales de MariaDB | `dolibarr` |
| `BACKUP_LIMIT` | Respaldos a conservar por tipo | `3` |
| `U_ID` / `G_ID` | UID/GID del usuario del host | `1000` |

---

## 6. USO

**Comandos más comunes:**

```bash
# Ver todos los comandos disponibles
make help

# Levantar/parar el stack
make dev-start          # Desarrollo
make stop               # Producción
make down               # Apagar todo

# Instalación y actualización
make install-doli       # Instalar Dolibarr
make doli-update        # Actualizar a la última versión

# Respaldos
make backup             # Crear respaldo
make backup-list        # Listar respaldos
make restore            # Restaurar respaldo
make backup-remove      # Eliminar uno específico
```

**Acceso a los contenedores:**

```bash
make ssh-dev            # Shell en el contenedor de la app
make ssh-db             # Shell en el contenedor de MariaDB
make mysql              # Cliente MySQL
```

---

## 7. RESPALDOS

El sistema de respaldos está diseñado para ser automático y seguro.

### Tipos de respaldo:

| Nomenclatura | Cuándo se crea | Propósito |
| :--- | :--- | :--- |
| `app-<timestamp>.tar.gz` | `make backup` | Respaldo manual |
| `app-pre-install-<timestamp>.tar.gz` | `make install-doli` | Antes de instalar |
| `app-pre-restore-<timestamp>.tar.gz` | `make restore` | Antes de restaurar |
| `app-pre-update-<timestamp>.tar.gz` | `make doli-update` | Antes de actualizar |

### Rotación:

El script `scripts/rotate-backups.sh` mantiene 3 respaldos por cada nomenclatura. Si hay más, elimina el más antiguo. Esto se aplica automáticamente tras cada operación.

### Flujo típico:

```bash
# 1. Crear un respaldo manual
make backup

# 2. Ver los respaldos disponibles
make backup-list

# 3. Restaurar (interactivo)
make restore

# 4. Eliminar un respaldo específico
make backup-remove

# 5. Eliminar TODOS (pide confirmación)
make backup-clean
```

---

## 8. TRAEFIK (DOMINIOS LOCALES Y SSL)

Traefik actúa como proxy inverso para servir Dolibarr en dominios locales como `dolibarr.local`.

### Configurar el dominio local:

**En Windows:**
1. Abre el Bloc de notas como Administrador.
2. Abre `C:\Windows\System32\drivers\etc\hosts`
3. Añade la línea:
   ```text
   127.0.0.1    dolibarr.local
   ```
4. Guarda sin extensión `.txt`.

**En WSL/Linux:**
```bash
echo "127.0.0.1    dolibarr.local" | sudo tee -a /etc/hosts
```

### Archivos de configuración:

- `traefik/configs/traefik-http.yml`: Configuración estática sin SSL
- `traefik/configs/traefik-ssl.yml`: Configuración estática con SSL
- `traefik/dynamic/middlewares.yml`: Middlewares (headers, auth, etc.)
- `traefik/dynamic/tls.yml`: Certificados TLS
- `traefik/dynamic/dashboard.yml`: Router del dashboard

### SSL local (autofirmado):

Para desarrollo local se usa un certificado autofirmado. El navegador mostrará una advertencia que deberás aceptar manualmente.

Para regenerar el certificado:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout traefik/certs/local.key \
  -out traefik/certs/local.crt \
  -subj "/CN=dolibarr.local"
```

### Dashboard de Traefik:

Accesible en:
- `http://localhost:8080/dashboard/`
- `http://dolibarr.local/dashboard/`

Protegido con autenticación básica. El hash se genera con:

```bash
docker run --rm httpd:alpine htpasswd -nbB admin "tu_contrasena"
```

---

## 9. COMANDOS DEL MAKEFILE

### Contenedores:
- `make build`: Reconstruir imágenes (producción)
- `make start`: Iniciar contenedores (producción)
- `make stop`: Detener contenedores
- `make down`: Apagar y eliminar contenedores
- `make restart`: Reiniciar contenedores
- `make dev-start`: Iniciar entorno de desarrollo
- `make dev-stop`: Detener entorno de desarrollo
- `make dev-down`: Apagar entorno de desarrollo
- `make traefik-start`: Iniciar con Traefik (HTTP)
- `make traefik-ssl-start`: Iniciar con Traefik (HTTPS)

### Instalación y actualización:
- `make install-doli`: Instalar Dolibarr (última versión)
- `make doli-update`: Actualizar Dolibarr

### Respaldos:
- `make backup`: Crear respaldo de `app/`
- `make backup-list`: Listar respaldos disponibles
- `make restore`: Restaurar respaldo (interactivo)
- `make backup-remove`: Eliminar un respaldo específico
- `make backup-clean`: Eliminar TODOS los respaldos

### Utilidades:
- `make env`: Crear `.env` desde `.env.example`
- `make help`: Mostrar ayuda
- `make git-status`: Estado del repo en `app/`

---

## 10. SOLUCIÓN DE PROBLEMAS

### Traefik no enruta el dominio:

1. Verifica que el contenedor está en la red correcta:
   ```bash
   docker inspect dolibarr --format \
     '{{range $k, $v := .NetworkSettings.Networks}}{{$k}} ({{$v.IPAddress}}){{"\n"}}{{end}}'
   ```
2. Verifica que Traefik ve el contenedor en el dashboard (`http://localhost:8080`).
3. Verifica los logs:
   ```bash
   docker logs traefik --tail 50
   ```

### Error 404 en el dashboard de Traefik:

La barra final es obligatoria:
- **Correcto**: `http://dolibarr.local/dashboard/`
- **Incorrecto**: `http://dolibarr.local/dashboard`

### Dolibarr no conecta con MariaDB:

1. Verifica que el hostname en el instalador sea `mariadb` (no `localhost`).
2. Verifica que las credenciales coincidan con las del `.env`.
3. Si cambiaste el `.env` después del primer arranque, elimina el volumen:
   ```bash
   docker compose -f docker-compose.traefik.yml down
   rm -rf mariadb_data/
   docker compose -f docker-compose.traefik.yml up -d
   ```

### Permisos denegados en `app/`:

Ajusta los permisos desde WSL:

```bash
sudo chown -R 1000:1000 app/
sudo chmod -R 755 app/documents app/custom
sudo chmod -R 555 app/public
```

### `'column: not found'` al ejecutar `make help`:

```bash
sudo apt install -y bsdmainutils
```

---

## 11. LICENCIA

Este proyecto se distribuye bajo la licencia **GPL-3.0**, la misma que Dolibarr.

---

## CRÉDITOS

- **Dolibarr ERP/CRM**: https://www.dolibarr.org/
- **Traefik Proxy**: https://traefik.io/
- **MariaDB**: https://mariadb.org/
- **Nginx**: https://nginx.org/
- **Docker**: https://www.docker.com/

---

## Autor

- **MTIE. Miguel Martinez** - [djmai](https://github.com/djmai)

[![Whatsapp](https://img.shields.io/badge/WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white&style=flat)](https://wa.link/7trr5f)
[![donate](https://www.paypalobjects.com/es_ES/i/btn/btn_donate_SM.gif)](https://paypal.me/IngMiguelMartinez?locale.x=es_XC)
[![Mercado Pago Donativo](https://img.shields.io/badge/-Mercado%20Pago-00B1EA?logo=mercadopago&logoColor=white&style=flat)](https://link.mercadopago.com.mx/sublisilaodonativo)



⌨️ con ❤️ por [MTIE. Miguel Martinez](https://github.com/djmai) 😊