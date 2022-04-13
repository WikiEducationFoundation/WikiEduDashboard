#!/bin/bash

# This is the entrypoint for the container which starts the dashbaord.
# Use docker host networking (--net=host) and access the application from
# host as http://localhost:3000

set -e
set -x

# Start dashboard
service mysql start
redis-server --daemonize yes
rails s -d -b 0.0.0.0
# yarn
yarn start
