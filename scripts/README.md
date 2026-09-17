# Scripts

Scripts auxiliares del proyecto.

## rotate-backups.sh

Rota los respaldos de `backups/app/` manteniendo un máximo de N por nomenclatura
(`app-`, `app-pre-install-`, `app-pre-restore-`, `app-pre-update-`).

Uso: ./scripts/rotate-backups.sh <BACKUP_DIR> <LIMIT>