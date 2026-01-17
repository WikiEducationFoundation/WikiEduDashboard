#!/bin/bash

set -euo pipefail

BACKUP_ROUTE="ROUTE_TO_BACKUPS"
QUERY_ROUTE="ROUTE_TO_QUERIES"
LOG_ROUTE="ROUTE_TO_LOGS"
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
LOG_FILE="$BACKUP_ROUTE/log-$datetime.log"
exec >>"$LOG_FILE" 2>&1

log "Starting"

# Create backup folder
mkdir -p $BACKUP_DIR

log "Waiting"

# Create waiting backup record
# Note: this uses credentials from my.cnf
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
