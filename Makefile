#!/bin/bash

UID := $(shell id -u)
GID := $(shell id -g)
DOCKER_DEV  = sublisilao-dev
DOCKER_PROD = sublisilao

DATETIME   := $(shell date +'%Y%m%d%H%M%S')
NEW_FOLDER := app-$(DATETIME)

# Repositorio oficial de Dolibarr
DOLIBARR_REPO := https://github.com/Dolibarr/dolibarr.git

# ==============================================================================
# Configuración de respaldos
# ==============================================================================
BACKUP_DIR     := backups
BACKUP_APP_DIR := $(BACKUP_DIR)/app
BACKUP_DB_DIR  := $(BACKUP_DIR)/db
BACKUP_LIMIT   := 3

# Variables leídas del .env (con fallback por si no existe)
DB_CONTAINER   := $(shell grep -E '^DB_NAME=' .env 2>/dev/null | cut -d= -f2)
DB_CONTAINER   := $(if $(DB_CONTAINER),$(DB_CONTAINER),mariadb)

DB_ROOT_PASS   := $(shell grep -E '^MARIA_ROOT_PASSWORD=' .env 2>/dev/null | cut -d= -f2)
DB_NAME_VAL    := $(shell grep -E '^MARIA_DATABASE=' .env 2>/dev/null | cut -d= -f2)

APP_FOLDER_VAL := $(shell grep -E '^APP_FOLDER=' .env 2>/dev/null | cut -d= -f2)
APP_FOLDER_VAL := $(if $(APP_FOLDER_VAL),$(APP_FOLDER_VAL),app)

help: ## Muestra la ayuda
	@echo 'usage: make [target]'
	@echo
	@echo 'targets:'
	@egrep '^(.+)\:\ ##\ (.+)' ${MAKEFILE_LIST} | column -t -c 2 -s ':#'

# ==============================================================================
# Gestión de contenedores - Dolibarr (produccion con Traefik, sin puerto local)
# ==============================================================================

build: ## Reconstruye todos los contenedores
	@U_ID=${UID} docker compose build

start: ## Inicia los contenedores
	@U_ID=${UID} docker compose up -d

stop: ## Para los contenedores
	@U_ID=${UID} docker compose stop

down: ## Apaga los contenedores
	@U_ID=${UID} docker compose down

restart: ## Reinicia los contenedores
	@$(MAKE) stop && $(MAKE) start

# ==============================================================================
# Gestión de contenedores - Dolibarr (desarrollo sin Traefik, con puerto local)
# ==============================================================================

dev-build: ## Reconstruye todos los contenedores de desarrollo
	@U_ID=${UID} docker compose -f docker-compose.dev.yml build

dev-start: ## Inicia los contenedores de desarrollo
	@U_ID=${UID} docker compose -f docker-compose.dev.yml up -d

dev-stop: ## Para los contenedores de desarrollo
	@U_ID=${UID} docker compose -f docker-compose.dev.yml stop

dev-down: ## Apaga los contenedores de desarrollo
	@U_ID=${UID} docker compose -f docker-compose.dev.yml down

dev-restart: ## Reinicia los contenedores de desarrollo
	@$(MAKE) dev-stop && $(MAKE) dev-start

# ==============================================================================
# Gestión de contenedores - Traefik (desarrollo con dominios locales)
# ==============================================================================

traefik-start: ## Inicia el stack con Traefik (dominios locales)
	@U_ID=${UID} docker compose -f docker-compose.traefik.yml up -d

traefik-stop: ## Para el stack con Traefik
	@U_ID=${UID} docker compose -f docker-compose.traefik.yml stop

traefik-down: ## Apaga el stack con Traefik
	@U_ID=${UID} docker compose -f docker-compose.traefik.yml down

traefik-restart: ## Reinicia el stack con Traefik
	@$(MAKE) traefik-stop && $(MAKE) traefik-start

# ==============================================================================
# Gestión de contenedores - Traefik (desarrollo con dominios locales)
# ==============================================================================

traefik-ssl-start: ## Inicia el stack con Traefik (dominios locales)
	@U_ID=${UID} docker compose -f docker-compose.traefik-ssl.yml up -d

traefik-ssl-stop: ## Para el stack con Traefik
	@U_ID=${UID} docker compose -f docker-compose.traefik-ssl.yml stop

traefik-ssl-down: ## Apaga el stack con Traefik
	@U_ID=${UID} docker compose -f docker-compose.traefik-ssl.yml down

traefik-ssl-restart: ## Reinicia el stack con Traefik
	@$(MAKE) traefik-ssl-stop && $(MAKE) traefik-ssl-start

# ==============================================================================
# Gestión de contenedores - Acceso a bash en los contenedores
# ==============================================================================

ssh-dev: ## Inicia bash en el contenedor development
	@docker exec -it --user ${UID} ${DOCKER_DEV} bash

ssh-prod: ## Inicia bash en el contenedor production
	@docker exec -it --user ${UID} ${DOCKER_PROD} bash

# =====================================================
# Gestión de instalación de Dolibarr ERP/CRM (vía Git)
# =====================================================

doli-install: ## Instala Dolibarr desde el repositorio oficial (última versión estable)
	@echo "================================================"
	@echo "¿Estás seguro de que deseas instalar Dolibarr ERP/CRM? (s/n)"
	@echo "================================================"
	@read -p "Confirma tu elección: " confirm && [ "$$confirm" = "s" ] || { echo "Instalación cancelada."; exit 1; }
	@echo ""
	@echo "================================================"
	@echo "🧹 Verificando residuos de instalaciones previas"
	@echo "================================================"
	@if [ -d dolibarr-src ]; then \
	    echo "⚠️  Se encontró 'dolibarr-src/' de una ejecución previa."; \
	    rm -rf dolibarr-src; \
	    echo "✅ Carpeta eliminada."; \
	else \
	    echo "✅ No hay residuos previos."; \
	fi
	@echo ""
	@echo "================================================"
	@echo "💾 Respaldando carpeta $(APP_FOLDER_VAL)/ actual (si existe)"
	@echo "================================================"
	@if [ -d $(APP_FOLDER_VAL) ]; then \
	    mkdir -p $(BACKUP_APP_DIR); \
	    PRE_TS=$$(date +'%Y%m%d-%H%M%S'); \
	    PRE_FILE="$(BACKUP_APP_DIR)/app-pre-install-$$PRE_TS.tar.gz"; \
	    echo "📦 Creando respaldo: $$PRE_FILE"; \
	    tar -czf "$$PRE_FILE" $(APP_FOLDER_VAL) && \
	    echo "✅ Respaldo previo creado (incluye README.md)" || \
	    { echo "❌ Error creando respaldo previo"; exit 1; }; \
	    echo ""; \
	    ./scripts/rotate-backups.sh $(BACKUP_APP_DIR) $(BACKUP_LIMIT); \
	    echo ""; \
	    rm -rf $(APP_FOLDER_VAL); \
	else \
	    echo "ℹ️  No existe $(APP_FOLDER_VAL)/. Instalación limpia."; \
	fi
	@echo "================================================"
	@echo "📁 Creando estructura de carpetas"
	@echo "================================================"
	mkdir -p $(APP_FOLDER_VAL)/documents $(APP_FOLDER_VAL)/custom $(APP_FOLDER_VAL)/public
	@echo "================================================"
	@echo "Clonando repositorio oficial de Dolibarr"
	@echo "================================================"
	git clone --depth 1 $(DOLIBARR_REPO) dolibarr-src
	@echo "================================================"
	@echo "Detectando el último tag estable..."
	@echo "================================================"
	cd dolibarr-src && \
		LATEST_TAG=$$(git ls-remote --tags --refs origin | \
			grep -oP 'refs/tags/\Kv?[0-9]+\.[0-9]+\.[0-9]+$$' | \
			grep -vE '(alpha|beta|rc|dev)' | \
			sort -V | tail -n1) && \
		if [ -z "$$LATEST_TAG" ]; then \
			echo "❌ No se pudo detectar un tag estable válido"; \
			echo ""; \
			echo "📋 Últimos 20 tags disponibles en el repositorio:"; \
			git ls-remote --tags --refs origin | tail -20; \
			exit 1; \
		fi && \
		echo "✅ Usando versión: $$LATEST_TAG" && \
		git fetch --depth 1 origin tag $$LATEST_TAG && \
		git checkout $$LATEST_TAG
	@echo "================================================"
	@echo "Moviendo archivos de htdocs a $(APP_FOLDER_VAL)/public"
	@echo "================================================"
	cp -afpR dolibarr-src/htdocs/. $(APP_FOLDER_VAL)/public/
	@echo "================================================"
	@echo "🧹 Limpiando carpeta temporal dolibarr-src"
	@echo "================================================"
	rm -rf dolibarr-src
	@echo "================================================"
	@echo "✅ Instalación finalizada"
	@echo
	@echo "Entorno de desarrollo:  $$ make dev-start"
	@echo "Entorno de producción:  $$ make start"
	@echo "================================================"

doli-update: ## Actualiza Dolibarr a la última versión estable
	@echo "================================================"
	@echo "¿Estás seguro de que deseas ACTUALIZAR Dolibarr ERP/CRM? (s/n)"
	@echo "================================================"
	@echo "Esto:"
	@echo "  1. Creará un respaldo automático (app-pre-update-<TS>.tar.gz)"
	@echo "  2. Sobrescribirá el contenido de $(APP_FOLDER_VAL)/public/"
	@echo "  3. NO tocará $(APP_FOLDER_VAL)/documents/ ni $(APP_FOLDER_VAL)/custom/"
	@echo "================================================"
	@read -p "Confirma tu elección: " confirm && [ "$$confirm" = "s" ] || { echo "Actualización cancelada."; exit 1; }
	@echo ""
	@echo "================================================"
	@echo "🔄 Actualizando Dolibarr a la última versión estable"
	@echo "================================================"
	@if [ ! -d $(APP_FOLDER_VAL)/public ]; then \
	    echo "❌ No existe $(APP_FOLDER_VAL)/public/. Ejecuta primero: make install-doli"; \
	    exit 1; \
	fi
	@echo ""
	@echo "🧹 Verificando residuos de ejecuciones previas"
	@echo "================================================"
	@if [ -d dolibarr-src ]; then \
	    echo "⚠️  Se encontró 'dolibarr-src/' de una ejecución previa."; \
	    rm -rf dolibarr-src; \
	    echo "✅ Carpeta eliminada."; \
	else \
	    echo "✅ No hay residuos previos."; \
	fi
	@echo ""
	@echo "💾 Respaldando estado actual antes de actualizar"
	@echo "================================================"
	@mkdir -p $(BACKUP_APP_DIR); \
	PRE_TS=$$(date +'%Y%m%d-%H%M%S'); \
	PRE_FILE="$(BACKUP_APP_DIR)/app-pre-update-$$PRE_TS.tar.gz"; \
	echo "📦 Creando respaldo: $$PRE_FILE"; \
	tar -czf "$$PRE_FILE" $(APP_FOLDER_VAL) && \
	echo "✅ Respaldo previo creado (incluye README.md)" || \
	{ echo "❌ Error creando respaldo previo"; exit 1; }; \
	echo ""; \
	./scripts/rotate-backups.sh $(BACKUP_APP_DIR) $(BACKUP_LIMIT)
	@echo ""
	@echo "================================================"
	@echo "Clonando repositorio oficial de Dolibarr"
	@echo "================================================"
	git clone --depth 1 $(DOLIBARR_REPO) dolibarr-src
	@echo "================================================"
	@echo "Detectando el último tag estable..."
	@echo "================================================"
	cd dolibarr-src && \
		LATEST_TAG=$$(git ls-remote --tags --refs origin | \
			grep -oP 'refs/tags/\Kv?[0-9]+\.[0-9]+\.[0-9]+$$' | \
			grep -vE '(alpha|beta|rc|dev)' | \
			sort -V | tail -n1) && \
		if [ -z "$$LATEST_TAG" ]; then \
			echo "❌ No se pudo detectar un tag estable válido"; \
			echo ""; \
			echo "📋 Últimos 20 tags disponibles en el repositorio:"; \
			git ls-remote --tags --refs origin | tail -20; \
			exit 1; \
		fi && \
		echo "✅ Usando versión: $$LATEST_TAG" && \
		git fetch --depth 1 origin tag $$LATEST_TAG && \
		git checkout $$LATEST_TAG
	@echo "================================================"
	@echo "Sobrescribiendo $(APP_FOLDER_VAL)/public con la nueva versión"
	@echo "================================================"
	cp -afpR dolibarr-src/htdocs/. $(APP_FOLDER_VAL)/public/
	@echo "================================================"
	@echo "🧹 Limpiando carpeta temporal dolibarr-src"
	@echo "================================================"
	rm -rf dolibarr-src
	@echo "================================================"
	@echo "✅ Actualización finalizada"
	@echo ""
	@echo "📦 Respaldo previo: $$PRE_FILE"
	@echo "🔍 Revisa los cambios con: make git-status"
	@echo "================================================"


# ==============================================================================
# Configuración inicial del proyecto
# ==============================================================================

env: ## Crea el archivo .env desde .env.example (no sobrescribe si ya existe)
	@if [ -f .env ]; then \
		echo "⚠️  El archivo .env ya existe. No se sobrescribe."; \
		echo "    Si quieres regenerarlo, borra primero: rm .env"; \
	else \
		if [ -f .env.example ]; then \
			cp .env.example .env; \
			echo "✅ Archivo .env creado desde .env.example"; \
			echo "👉 Revisa y ajusta los valores antes de ejecutar 'make start' o 'make dev'."; \
		else \
			echo "❌ No se encontró .env.example en la raíz del proyecto."; \
			exit 1; \
		fi; \
	fi


# ==============================================================================
# Gestión de respaldos (backup / restore)
# ==============================================================================

backup: ## Crea respaldo de la carpeta app/ (rota a 3 máximo)
	@echo "================================================"
	@echo "🔒 Iniciando respaldo de la carpeta APP"
	@echo "================================================"
	@mkdir -p $(BACKUP_APP_DIR)
	@DATETIME=$$(date +'%Y%m%d-%H%M%S'); \
	APP_FILE="$(BACKUP_APP_DIR)/app-$$DATETIME.tar.gz"; \
	echo "📦 Respaldando carpeta $(APP_FOLDER_VAL)/ -> $$APP_FILE"; \
	tar -czf "$$APP_FILE" $(APP_FOLDER_VAL) && \
	echo "✅ Respaldo de app completado" || \
	{ echo "❌ Error respaldando app"; exit 1; }; \
	echo ""; \
	./scripts/rotate-backups.sh $(BACKUP_APP_DIR) $(BACKUP_LIMIT); \
	echo ""; \
	echo "================================================"; \
	echo "✅ Respaldo finalizado correctamente"; \
	echo "   App:  $$APP_FILE"; \
	echo "================================================"

backup-list: ## Lista los respaldos disponibles
	@echo "================================================"
	@echo "📦 Respaldos de APP disponibles"
	@echo "================================================"
	@if [ -d $(BACKUP_APP_DIR) ] && [ -n "$$(ls -A $(BACKUP_APP_DIR)/app-*.tar.gz 2>/dev/null)" ]; then \
		ls -1t $(BACKUP_APP_DIR)/app-*.tar.gz | nl -w2 -s') '; \
	else \
		echo "  (sin respaldos)"; \
	fi
	@echo ""

restore: ## Restaura un respaldo de app/ (interactivo, incluye pre-install y pre-restore)
	@echo "================================================"
	@echo "♻️  Restauración de respaldos de APP"
	@echo "================================================"
	@ALL_BACKUPS=$$(ls -1t $(BACKUP_APP_DIR)/app-*.tar.gz 2>/dev/null); \
	if [ -z "$$ALL_BACKUPS" ]; then \
	    echo "❌ No hay respaldos disponibles en $(BACKUP_APP_DIR)/"; \
	    echo ""; \
	    echo "💡 Crea un respaldo con: make backup"; \
	    exit 1; \
	fi
	@echo ""
	@echo "📦 Respaldos disponibles:"
	@echo ""
	@i=0; \
	for f in $$(ls -1t $(BACKUP_APP_DIR)/app-*.tar.gz); do \
	    i=$$((i+1)); \
	    NAME=$$(basename $$f .tar.gz); \
	    SIZE=$$(du -h $$f | cut -f1); \
	    if echo "$$NAME" | grep -q 'pre-restore'; then \
	        TYPE="🛡️  pre-restore"; \
	        TS=$$(echo $$NAME | sed -E 's/app-pre-restore-(.*)/\1/'); \
	    elif echo "$$NAME" | grep -q 'pre-install'; then \
	        TYPE="🛡️  pre-install"; \
	        TS=$$(echo $$NAME | sed -E 's/app-pre-install-(.*)/\1/'); \
	    else \
	        TYPE="📦 normal      "; \
	        TS=$$(echo $$NAME | sed -E 's/app-(.*)/\1/'); \
	    fi; \
	    DATE=$$(echo $$TS | sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3 \4:\5:\6/'); \
	    printf "  %2d) [%s]  %s  (%s)  %s\n" $$i "$$TYPE" "$$TS" "$$SIZE" "$$DATE"; \
	done; \
	echo ""; \
	echo "  💡 [normal]      Respaldo manual creado con 'make backup'"; \
	echo "  💡 [pre-restore] Respaldo automático antes de un 'make restore'"; \
	echo "  💡 [pre-install] Respaldo automático antes de un 'make install-doli'"; \
	echo ""; \
	read -p "Elige el número del respaldo a restaurar (0 para cancelar): " CHOICE; \
	if [ "$$CHOICE" = "0" ] || [ -z "$$CHOICE" ]; then \
	    echo "Restauración cancelada."; exit 0; \
	fi; \
	\
	APP_FILE=$$(ls -1t $(BACKUP_APP_DIR)/app-*.tar.gz | sed -n "$${CHOICE}p"); \
	if [ -z "$$APP_FILE" ]; then echo "❌ Selección inválida."; exit 1; fi; \
	\
	IS_PRE=$$(basename $$APP_FILE | grep -E 'pre-restore|pre-install' || true); \
	\
	echo ""; \
	echo "================================================"; \
	echo "⚠️  ADVERTENCIA: Se va a restaurar"; \
	echo "   APP:  $$APP_FILE"; \
	if [ -n "$$IS_PRE" ]; then \
	    echo ""; \
	    echo "   🛡️  Estás restaurando un respaldo AUTOMÁTICO (pre-*)."; \
	    echo "   Esto sobrescribirá el estado actual con el estado"; \
	    echo "   que había justo antes del último restore/install."; \
	fi; \
	echo "================================================"; \
	echo "Esto SOBRESCRIBIRÁ la carpeta $(APP_FOLDER_VAL)/."; \
	echo "Se borrará TODO el contenido de $(APP_FOLDER_VAL)/."; \
	echo ""; \
	read -p "¿Confirmas? (s/n): " CONFIRM; \
	if [ "$$CONFIRM" != "s" ]; then echo "Restauración cancelada."; exit 0; fi; \
	\
	echo ""; \
	echo "💾 Respaldando estado actual antes de restaurar..."; \
	mkdir -p $(BACKUP_APP_DIR); \
	PRE_TS=$$(date +'%Y%m%d-%H%M%S'); \
	PRE_APP_FILE="$(BACKUP_APP_DIR)/app-pre-restore-$$PRE_TS.tar.gz"; \
	if [ -d $(APP_FOLDER_VAL) ]; then \
	    tar -czf "$$PRE_APP_FILE" $(APP_FOLDER_VAL) && \
	    echo "✅ Respaldo de seguridad creado: $$PRE_APP_FILE" || \
	    { echo "❌ Error respaldando app"; exit 1; }; \
	else \
	    echo "ℹ️  No existe $(APP_FOLDER_VAL)/. Se omite respaldo previo."; \
	fi; \
	echo ""; \
	./scripts/rotate-backups.sh $(BACKUP_APP_DIR) $(BACKUP_LIMIT); \
	echo ""; \
	echo "🗑️  Borrando contenido de $(APP_FOLDER_VAL)/"; \
	find $(APP_FOLDER_VAL) -mindepth 1 -maxdepth 1 -exec rm -rf {} \; 2>/dev/null || true; \
	echo "✅ Contenido eliminado"; \
	echo ""; \
	echo "🔄 Restaurando APP desde el respaldo..."; \
	tar -xzf "$$APP_FILE"; \
	echo "✅ APP restaurada"; \
	echo ""; \
	echo "================================================"; \
	echo "✅ Restauración completada"; \
	echo "   Respaldo de seguridad: $$PRE_APP_FILE"; \
	echo "================================================"

backup-clean: ## Elimina TODOS los respaldos (pide confirmación)
	@echo "================================================"
	@echo "⚠️  Esto eliminará TODOS los respaldos de APP"
	@echo "    Ubicación: $(BACKUP_APP_DIR)/"
	@echo "================================================"
	@COUNT=$$(ls -1 $(BACKUP_APP_DIR)/app-*.tar.gz 2>/dev/null | wc -l); \
	if [ "$$COUNT" = "0" ]; then \
	    echo "ℹ️  No hay respaldos que eliminar."; \
	    exit 0; \
	fi; \
	echo "📦 Se eliminarán $$COUNT respaldo(s):"; \
	ls -1t $(BACKUP_APP_DIR)/app-*.tar.gz | sed 's/^/   /'; \
	echo ""; \
	read -p "¿Confirmas? (s/n): " confirm && [ "$$confirm" = "s" ] || { echo "Cancelado."; exit 1; }
	@rm -f $(BACKUP_APP_DIR)/app-*.tar.gz
	@echo "✅ Respaldos eliminados"

backup-remove: ## Elimina un respaldo específico (interactivo)
	@echo "================================================"
	@echo "🗑️  Eliminar un respaldo de APP"
	@echo "================================================"
	@ALL_BACKUPS=$$(ls -1t $(BACKUP_APP_DIR)/app-*.tar.gz 2>/dev/null); \
	if [ -z "$$ALL_BACKUPS" ]; then \
	    echo "❌ No hay respaldos disponibles en $(BACKUP_APP_DIR)/"; \
	    exit 1; \
	fi
	@echo ""
	@echo "📦 Respaldos disponibles:"
	@echo ""
	@i=0; \
	for f in $$(ls -1t $(BACKUP_APP_DIR)/app-*.tar.gz); do \
	    i=$$((i+1)); \
	    NAME=$$(basename $$f .tar.gz); \
	    SIZE=$$(du -h $$f | cut -f1); \
	    if echo "$$NAME" | grep -q 'pre-restore'; then \
	        TYPE="🛡️  pre-restore"; \
	        TS=$$(echo $$NAME | sed -E 's/app-pre-restore-(.*)/\1/'); \
	    elif echo "$$NAME" | grep -q 'pre-install'; then \
	        TYPE="🛡️  pre-install"; \
	        TS=$$(echo $$NAME | sed -E 's/app-pre-install-(.*)/\1/'); \
	    else \
	        TYPE="📦 normal      "; \
	        TS=$$(echo $$NAME | sed -E 's/app-(.*)/\1/'); \
	    fi; \
	    DATE=$$(echo $$TS | sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3 \4:\5:\6/'); \
	    printf "  %2d) [%s]  %s  (%s)  %s\n" $$i "$$TYPE" "$$TS" "$$SIZE" "$$DATE"; \
	done; \
	echo ""; \
	read -p "Elige el número del respaldo a ELIMINAR (0 para cancelar): " CHOICE; \
	if [ "$$CHOICE" = "0" ] || [ -z "$$CHOICE" ]; then \
	    echo "❌ Eliminación cancelada."; exit 0; \
	fi; \
	\
	APP_FILE=$$(ls -1t $(BACKUP_APP_DIR)/app-*.tar.gz | sed -n "$${CHOICE}p"); \
	if [ -z "$$APP_FILE" ]; then echo "❌ Selección inválida."; exit 1; fi; \
	\
	echo ""; \
	echo "================================================"; \
	echo "⚠️  Se va a ELIMINAR permanentemente:"; \
	echo "   $$APP_FILE"; \
	echo "================================================"; \
	read -p "¿Confirmas? (s/n): " CONFIRM; \
	if [ "$$CONFIRM" != "s" ]; then echo "Eliminación cancelada."; exit 0; fi; \
	\
	rm -f "$$APP_FILE" && \
	echo "✅ Respaldo eliminado: $$APP_FILE" || \
	{ echo "❌ Error eliminando el respaldo"; exit 1; }