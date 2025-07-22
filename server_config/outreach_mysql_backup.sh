#!/bin/bash

# This script backs up the DB_NAME database into the specified BACKUP_PATH
#   and syncs it to REMOTE_USER_HOST under REMOTE_BACKUP_PATH

### configuration ###

BACKUP_PATH=/srv/outreach_backup/db/weekly/dashboard
REMOTE_BACKUP_PATH=/var/outreach_backup/db/weekly/dashboard
BACKUP_EXPIRY=90 # backups older than this (number of days) will be deleted
DB_NAME=dashboard
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=password
REMOTE_USER_HOST=wikiedu-backups # as defined in /root/.ssh/config

### start of script ###

# create backups directory if it does not exist and move to it
mkdir -p $BACKUP_PATH
cd $BACKUP_PATH

# create new dump with current timestamp and week number as the filename
FILENAME=$(date +%Y-%m-%d_%Hh%Mm_%U)
mysqldump --user=$DB_USER --password=$DB_PASSWORD --host=$DB_HOST $DB_NAME > $FILENAME.sql

# gzip, also removing the full-sized dump
gzip $FILENAME.sql

# current date in Unix time
CUR_DATE_EPOCH=$(date +%s)

# current date minus 90 days (in seconds)
OLD_DATE_EPOCH=$((CUR_DATE_EPOCH - 60 * 60 * 24 * BACKUP_EXPIRY))

# remove old backups
for dumpfile in *.sql.gz
do
  # get Unix time of $dumpfile (last modified)
  dump_date_epoch=$(date -r $dumpfile +%s)

  # delete if expired
  if [ $dump_date_epoch -le $OLD_DATE_EPOCH ];
  then
    rm $dumpfile;
  fi
done

# sync to backup server, removing any files there that have been removed locally
rsync -avz0 --delete $BACKUP_PATH $REMOTE_USER_HOST:$REMOTE_BACKUP_PATH/..
