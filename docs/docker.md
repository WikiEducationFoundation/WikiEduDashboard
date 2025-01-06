# Docker Setup

This document outlines how you can setup a containerized testing/development environment quickly using docker. Using a containerized dashboard image allows for a faster and reproducible test setup. We first have to build the Docker image and then run the container.

### TL;DR
```sh
$ docker build -t wiki-edu-dashboard .
$ docker compose up -d
```

## Build Docker Image

Make sure the docker daemon is running. Else, `service docker status`. Then, from the root of your development directory (`WikiEduDashboard`), issue the build command:
 ```sh
 $ docker build -t wiki-edu-dashboard .
 ```
 This builds the `wiki-edu-dashboard` container image using the Dockerfile. The dashboard container image is based on the official `ruby:3.1.2-slim` [base image](https://hub.docker.com/_/ruby/). The container image only contains application with all the necessary dependencies.

## Run
MySQL and redis is required to be able running docker image. For a developer's ease of use, it's recommended to use `docker-compose.yml` which will run `wiki-edu-dashboard` with MySQL and redis.

### Docker Compose
docker compose will mount project directory to the container for development purpose. It will expose port `3000` for rails applications and port `8080` for websocket. Run the compose with the command as follows:
```sh
# Run all service
$ docker compose up
``` 
This command will start init container, it will wait for MySQL and Redis container to start. Then init container will try to initialized db. If the init container success, app container will start and mount `./` (project directory) to the `/app` (container `WORKDIR` location). Last, the docker compose will expose the port to make sure the container can be accessible from host computer.
```
=> Booting Puma
=> Rails 7.0.4 application starting in development
=> Run `bin/rails server --help` for more startup options
...
...
<s> [webpack.Progress] 100%

60 assets
3389 modules
webpack 5.73.0 compiled successfully in 17961 ms
```
At this point, developers can continue working in their local work directories and the changes would be reflected inside the container. Live changes are visible on `http://localhost:3000` from the host.


## Monitoring the Dashboard Container
Some useful commands and tools that can be used to monitor and administer the containers are:
  * [`ctop`](https://github.com/bcicen/ctop)
  * `docker images`
  * `docker inspect <container id>`
  * `docker logs -f <container-name>` (see the logs)
  * `docker exec -it <container-name> /bin/bash` (Login into container)

Further Reference: https://docs.docker.com/reference/

### Troubleshooting

If you are using Linux you may encounter permission error when trying to change file/folder on host computer. This is caused root user used while running container. To fix this issue, you can change the owner of the file/folder with the following commands on the root project directory:
```sh
$ sudo chown $USER:$GROUPS -R ./
```
The command will change the owner of all file inside project directory to the `$USER:$GROUPS`

If you encounter the following error when connecting to the database: _"There is an issue connecting with your hostname mysql"_, please run the following command:
```sh
bash ./update_hosts.sh
```
This script automatically resolves the issue by ensuring proper network mapping in your system's ```/etc/hosts``` file, facilitating seamless database connections. It retrieves the IP address of the MySQL Docker container, checks for any existing hostname entries, and updates or removes outdated ones. This process ensures that the hostname ```mysql``` is correctly mapped to the container’s IP address.
This bash script is designed for Linux distributions like Fedora.
