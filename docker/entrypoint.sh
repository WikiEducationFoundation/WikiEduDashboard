#!/bin/bash

sync_config() {
    key=$1
    env=$2
    target_file=$3

    if [ -n "$env" ]; then
        sed -i "s/$key: .*/$key: $env/g" $target_file
    fi
}

if [ ! -f config/database.yml ]; then
    cp config/database.example.yml config/database.yml
fi

if [ ! -f config/application.yml ]; then
    cp config/application.example.yml config/application.yml
fi

sync_config username $MYSQL_USER config/database.yml
sync_config password $MYSQL_PASSWORD config/database.yml
sync_config host $MYSQL_HOST config/database.yml
sync_config port $MYSQL_PORT config/database.yml

command=$1

case "$command" in 
    "init")
        rake db:migrate
        rake db:migrate RAILS_ENV=test
        ;;
    "start")
        rails s -d -b 0.0.0.0
        yarn start
        ;;
    *)
        echo "Invalid option, try to exec"
        exec "$@"
        ;;
esac