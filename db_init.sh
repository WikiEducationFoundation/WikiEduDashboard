#!/bin/bash

# This script initializes the DB by creating users, granting privileges
# and migrating the dev and test DBs in order to persist the DB in the
# container image itself

set -e
set -x

# Start mariadb server
service mysql start
sleep 5

# Init DBs
echo "CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
      exit" | mysql && printf "$\n[DATABSE CREATED]\n"

echo "CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'wikiedu';
      GRANT ALL PRIVILEGES ON dashboard . * TO 'wiki'@'localhost';
      GRANT ALL PRIVILEGES ON dashboard_testing . * TO 'wiki'@'localhost';
      exit" | mysql > /dev/null && printf "\n[USER CREATED]\n"

# Migrate dev and test DBs
rake db:migrate
rake db:migrate RAILS_ENV=test

service mysql stop
