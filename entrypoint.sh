#!/bin/bash

# This is the entrypoint for the container which initializes the DB and starts
# the dashbaord on 3000. Use docker host networking "--net=host" and access the 
# application from host as http://localhost:3000

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

# Start dashboard
redis-server --daemonize yes
sleep 10
rails s -d
sleep 10
gulp
