#!/bin/bash

# This is the entrypoint for the container which starts the dashbaord. 
# Use docker host networking (--net=host) and access the application from 
# host as http://localhost:3000

set -e
set -x

# Start dashboard
service mysql start
sleep 5
redis-server --daemonize yes
sleep 10
rails s -d
sleep 10
gulp
