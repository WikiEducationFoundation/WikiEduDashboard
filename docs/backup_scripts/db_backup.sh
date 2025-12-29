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
ssh peony-sidekiq.globaleducation.eqiad1.wikimedia.cloud /home/backup_user/post_db_backup_peony-sidekiq.sh
# Restart sidekiq processes in peony-sidekiq-medium through ssh
ssh peony-sidekiq-medium.globaleducation.eqiad1.wikimedia.cloud /home/backup_user/post_db_backup_peony-sidekiq-medium.sh
# Restart sidekiq processes in peony-sidekiq-3 through ssh
ssh peony-sidekiq-3.globaleducation.eqiad1.wikimedia.cloud /home/backup_user/post_db_backup_peony-sidekiq-3.sh
