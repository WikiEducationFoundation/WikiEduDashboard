#!/bin/bash

# # Check if Docker Compose is up and running
# docker-compose ps mysql &>/dev/null
# if [ $? -ne 0 ]; then
#     echo "MySQL container is not running. Please ensure Docker Compose is up."
#     exit 1
# fi

# Get the MySQL container ID
MYSQL_CONTAINER_ID=$(docker ps --format '{{.ID}} {{.Names}}' | grep 'wikiedudashboard-mysql-1' | awk '{print $1}')

echo $MYSQL_CONTAINER_ID

# Fetch the IP address of the MySQL container
MYSQL_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$MYSQL_CONTAINER_ID")

# Check if we successfully fetched the IP address
if [ -z "$MYSQL_IP" ]; then
    echo "Could not retrieve MySQL container IP address."
    exit 1
fi

# Print the IP address
echo "MySQL IP address: $MYSQL_IP"

# Backup /etc/hosts file
sudo cp /etc/hosts /etc/hosts.bak

# Add MySQL container IP to /etc/hosts
if ! grep -q "$MYSQL_IP mysql" /etc/hosts; then
    echo "Adding MySQL container IP address to /etc/hosts"
    echo "$MYSQL_IP mysql" | sudo tee -a /etc/hosts > /dev/null
else
    echo "MySQL entry already exists in /etc/hosts."
fi

# Print success message
echo "MySQL IP address has been added to /etc/hosts."
