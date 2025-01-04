#!/bin/bash

# Get the MySQL container ID
MYSQL_CONTAINER_ID=$(docker ps --format '{{.ID}} {{.Names}}' | grep 'wikiedudashboard-mysql-1' | awk '{print $1}')

echo $MYSQL_CONTAINER_ID

# Fetch the IP address of the MySQL container
MYSQL_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$MYSQL_CONTAINER_ID")

# Check if we successfully fetched the IP address
if [ -z "$MYSQL_IP" ]; then
    echo "Failed to retrieve the MySQL container IP address. Please ensure the Docker containers are running by executing 'docker compose up -d'."
    if grep -q "$MYSQL_IP mysql" /etc/hosts; then
    sudo sed -i '/[[:space:]]mysql$/d' /etc/hosts
    echo "MySQL entry removed from /etc/hosts."
    fi
    
    exit 1
fi

# Print the IP address
echo "MySQL IP address: $MYSQL_IP"

# Backup /etc/hosts file
sudo cp /etc/hosts /etc/hosts.bak

# Add MySQL container IP to /etc/hosts
if grep -q "$MYSQL_IP mysql" /etc/hosts; then
    echo "MySQL entry already exists in /etc/hosts."
    # Remove existing MySQL entry from /etc/hosts (if it exists)
    sudo sed -i '/[[:space:]]mysql$/d' /etc/hosts
    echo "Removed old MySQL entry from /etc/hosts."
fi

# Add new MySQL container IP address to /etc/hosts
echo "Adding MySQL container IP address to /etc/hosts"
echo "$MYSQL_IP mysql" | sudo tee -a /etc/hosts > /dev/null

# Print success message
echo "MySQL IP address has been added to /etc/hosts."