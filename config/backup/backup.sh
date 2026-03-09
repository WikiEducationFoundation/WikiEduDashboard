#!/bin/bash

set -euo pipefail

BACKUP_ROUTE="ROUTE_TO_BACKUPS"
QUERY_ROUTE="ROUTE_TO_QUERIES"
JSON_ENDPOINT="https://outreachdashboard.wmflabs.org/system/can_start_backup.json"

log() {
  printf '%s : %s\n' "$(date '+%m%d%Y %T')" "$1" >> "$LOG_FILE"
}

on_error() {
  local exit_code=$?
  log "ERROR at line $1: command '$BASH_COMMAND' exited with $exit_code"

  mysql < "$QUERY_ROUTE/failed.sql" || true

  exit "$exit_code"
}

check_app_is_ready_for_backup() {
  curl -s \
  -o /dev/null  \
  -w "%{http_code}" \
  $JSON_ENDPOINT
}

wait_until_ready_for_backup() {
  local status=$(check_app_is_ready_for_backup)

  while [ $status != 200 ];
  do
      sleep 300
      status=$(check_app_is_ready_for_backup)
  done
}

trap 'on_error $LINENO' ERR

# Set datetime
printf -v datetime '%(%Y-%m-%d-%H:%M:%S)T' -1
BACKUP_DIR="$BACKUP_ROUTE/$datetime"

# Create backup folder
mkdir -p $BACKUP_DIR

LOG_FILE="$BACKUP_DIR/log-$datetime.log"
exec >>"$LOG_FILE" 2>&1

log "Starting"

# Calculate min free space in bytes based on last backup
LATEST_DIR=$(ls -1d "$BACKUP_ROUTE"/*/ | sort | tail -2 | head -1)
LAST_BACKUP=$(ls "$LATEST_DIR"/*.sql.gz | head -1)

LAST_BACKUP_SIZE=$(stat -c%s "$LAST_BACKUP")
# Backups are stored in compressed form. We require 30x the size of the previous backup,
# assuming the compressed version is about 10 times smaller 
MIN_FREE_SPACE=$(( LAST_BACKUP_SIZE * 30 ))

# Calculate free space in bytes
FREE_SPACE=$(df -B 1 --output=avail $BACKUP_DIR | tail -1 | tr -dc '0-9')
if [ $FREE_SPACE -lt $MIN_FREE_SPACE ]; then
  log "Not enough free space. Aborting"
  exit 1
fi

# Create waiting backup record
mysql < $QUERY_ROUTE/waiting.sql

# Sleep two minutes to guarantee that all processes see the new data table record
sleep 120

wait_until_ready_for_backup

log "Ready"
# Update waiting backup record to 'running'
mysql < $QUERY_ROUTE/running.sql

log "Running backup"
# Run backup
mariadb-dump --single-transaction --routines --databases dashboard | gzip > $BACKUP_DIR/dashboard-dump-$datetime.sql.gz

log "Finishing"
# Update running backup record to 'finished'
mysql < $QUERY_ROUTE/finished.sql

# Remove oldest backup if there are more than three
MIN_BACKUPS_NUMBER=3
CURRENT_BACKUPS_NUMBER=$(ls -1d "$BACKUP_ROUTE"/*/ | wc -l)
if [ $CURRENT_BACKUPS_NUMBER -gt $MIN_BACKUPS_NUMBER ]; then
  OLDEST_BACKUP=$(ls -1d "$BACKUP_ROUTE"/*/ | sort | head -1)
  log "Removing $OLDEST_BACKUP"
  rm -r $OLDEST_BACKUP
fi
