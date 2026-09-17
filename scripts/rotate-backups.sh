#!/bin/bash
# ==============================================================================
# rotate-backups.sh
#
# Rota los respaldos de la carpeta backups/app/ manteniendo un máximo de N
# respaldos por cada nomenclatura.
#
# Uso: ./scripts/rotate-backups.sh <BACKUP_DIR> <LIMIT>
#
# Nomenclaturas soportadas:
#   - app-<timestamp>.tar.gz
#   - app-pre-install-<timestamp>.tar.gz
#   - app-pre-restore-<timestamp>.tar.gz
#
# Ejemplo:
#   ./scripts/rotate-backups.sh backups/app 3
# ==============================================================================

set -euo pipefail

BACKUP_DIR="${1:-backups/app}"
LIMIT="${2:-3}"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "ℹ️  Directorio '$BACKUP_DIR' no existe. Nada que rotar."
    exit 0
fi

cd "$BACKUP_DIR"

# ------------------------------------------------------------------------------
# Rotar respaldos NORMALES: app-<timestamp>.tar.gz
# Excluye los que tienen "pre-install" o "pre-restore" en el nombre
# ------------------------------------------------------------------------------
echo "🧹 Rotando respaldos normales (app-<timestamp>.tar.gz)"
NORMAL_COUNT=$(ls -1t app-*.tar.gz 2>/dev/null | grep -v 'pre-install' | grep -v 'pre-restore' | wc -l)
if [ "$NORMAL_COUNT" -gt "$LIMIT" ]; then
    ls -1t app-*.tar.gz 2>/dev/null | grep -v 'pre-install' | grep -v 'pre-restore' | \
        tail -n +$((LIMIT + 1)) | \
        while read old; do
            echo "  🗑️  Eliminando: $old"
            rm -f "$old"
        done
else
    echo "  ✅ Dentro del límite ($NORMAL_COUNT/$LIMIT)"
fi

# ------------------------------------------------------------------------------
# Rotar respaldos PRE-INSTALL: app-pre-install-<timestamp>.tar.gz
# ------------------------------------------------------------------------------
echo "🧹 Rotando respaldos pre-install (app-pre-install-<timestamp>.tar.gz)"
PRE_INSTALL_COUNT=$(ls -1t app-pre-install-*.tar.gz 2>/dev/null | wc -l)
if [ "$PRE_INSTALL_COUNT" -gt "$LIMIT" ]; then
    ls -1t app-pre-install-*.tar.gz 2>/dev/null | \
        tail -n +$((LIMIT + 1)) | \
        while read old; do
            echo "  🗑️  Eliminando: $old"
            rm -f "$old"
        done
else
    echo "  ✅ Dentro del límite ($PRE_INSTALL_COUNT/$LIMIT)"
fi

# ------------------------------------------------------------------------------
# Rotar respaldos PRE-RESTORE: app-pre-restore-<timestamp>.tar.gz
# ------------------------------------------------------------------------------
echo "🧹 Rotando respaldos pre-restore (app-pre-restore-<timestamp>.tar.gz)"
PRE_RESTORE_COUNT=$(ls -1t app-pre-restore-*.tar.gz 2>/dev/null | wc -l)
if [ "$PRE_RESTORE_COUNT" -gt "$LIMIT" ]; then
    ls -1t app-pre-restore-*.tar.gz 2>/dev/null | \
        tail -n +$((LIMIT + 1)) | \
        while read old; do
            echo "  🗑️  Eliminando: $old"
            rm -f "$old"
        done
else
    echo "  ✅ Dentro del límite ($PRE_RESTORE_COUNT/$LIMIT)"
fi

echo "✅ Rotación completada"