# Docker Setup

This document outlines how you can setup a containerized testing/development environment quickly using docker. Using a containerized dashboard image allows for a faster and reproducible test setup. We first have to build the Docker image and then run the container. 

### TL;DR
```sh
$ docker build -t wiki-edu-dashboard .
$ docker run --net=host -it -v /path/to/WikiEduDashboard:/usr/src/app wiki-edu-dashboard
```

## Build Docker Image

Make sure the docker daemon is running. Else, `service docker status`. Then, from the root of your development directory (`WikiEduDashboard`), issue the build command:
 ```sh
 $ docker build -t wiki-edu-dashboard .
 ```
 This builds the `wiki-edu-dashboard` container image using the Dockerfile. The dashboard container image is based on the official `ruby:2.5.0` [base image](https://hub.docker.com/_/ruby/). The container image contains all the necessary dependencies as well as an initialized MariaDB database as required by the Wiki Edu Dashboard. 

## Run
The current docker image can be used for testing, local deploys or development purposes. `docker run` initializes the setup and spawns a container which starts serving the dashboard on `http://localhost:3000`. Also, this requires port `3000` to be open on the host.

### Development Setup
For a developer's ease of use, it is desirable to have the container auto update as the source code changes in the development directory. Therefore, we use Docker volumes to mount the local directory and have its real-time changes accessible inside the container. Run the container with the `-v` option as follows:
 ```sh
 $ docker run --net=host -it -v /path/to/WikiEduDashboard:/usr/src/app wiki-edu-dashboard
```
This starts the container with host networking and allows `/path/to/WikiEduDashboard` (developer's working directory) to be accessible from the `WORKDIR` of container. For WikiEduDashboard Docker image, the working directory has been set as `/usr/src/app`. Once the container starts, you should start expecting the following prompts and `gulp` to have started with its status messages waiting for live changes.
```
[ ok ] Starting MariaDB database server: mysqld ..
+ redis-server --daemonize yes
+ rails s -d -b 0.0.0.0
=> Booting WEBrick
=> Rails 5.1.6 application starting in development on http://localhost:3000
=> Run `rails server -h` for more startup options
..
```
At this point, developers can continue working in their local work directories and the changes would be reflected inside the container. Live changes are visible on `http://localhost:3000` from the host.

### Testing Deployment
The above container can also be spawned without the need of volumes, thus freezing the code in the container to be the same as latest image built using `docker build`. Developers can also tag multiple container image builds using `docker build -t name:tag .` To deploy a test build:

```sh
$ docker run --net=host -it wiki-edu-dashboard
```

Open a browser on the host at `http://localhost:3000` and start testing.

## Monitoring the Dashboard Container
Some useful commands and tools that can be used to monitor and administer the containers are:
  * [`ctop`](https://github.com/bcicen/ctop)
  * `docker images`
  * `docker inspect <container id>`

Further Reference: https://docs.docker.com/reference/

