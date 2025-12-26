#!/bin/bash

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting pre DB backup process"
bin/rails runner pre_db_backup.rb

log "Starting backup"
# run backup

log "Starting post DB backup process"
# Restart sidekiq in web-server
./post_db_backup_peony-web.sh
# Restart sidekiq processes in peony-sidekiq through ssh
# Restart sidekiq processes in peony-sidekiq-medium through ssh
# Restart sidekiq processes in peony-sidekiq-3 through ssh
