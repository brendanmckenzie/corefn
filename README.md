# corefn

CoreFn is an framework for running stateless code in a controlled environment that executes in response to external actions where the host environment scales automatically to meet demand.

The environment consists of the following components.

 1. Docker.  Docker is at the core of this environment.  It's not only responsible for running the infrastructure, it's responsible for running the actual code.
 2. Redis. Redis is used to keep track of what's running in the environment.
 3. The Host. The host which, at present, is an nginx host that serves content via a Lua script.  This component is responsible for routing external actions to the appropriate code endpoint.  It works by receiving an HTTP, finding out what docker image relates to the request, checking to see if a docker container is running, if not it spins up a new one, passes the request body to the container then sends a response back as it receives it from the container.
 4. The Repository.  The Git repository is responsible for hosting the Git repositories that house the code which gets executed.  Code is committed to a Git repository, pushed to the git host which bootstraps the code, builds a docker image with just the executable in it and stores it in the docker image store.
 5. The Cleaner.  Docker images are spun up on demand, however they have a 60 second grace period before being shut down.  If mulitple requests come in to the same host for the same piece of code, only one docker image will be used.  After 60 seconds of inactivity the cleaner shuts down the container.

## Getting started

To make use of this framework you'll need a host running Docker with the .NET Core SDK installed.  From there follow these steps to get up and running.

By default everything is stored in docker volumes on the host under `/var/func` but this can be changed by modifying the `docker-compose.yml` file.

 1. Clone this repository
 2. Run the `mkutils.sh` script in the docker/git folder
 3. Run `docker-compose up -d` in the docker folder
 4. Create a repository in `/var/func/projects`, for an example of what a repository should look like, check out [this repository](https://github.com/brendanmckenzie/corefn-demo).

## Workflow

The workflow for getting code running in the environment

 1. Project is created containing functionality
 2. Project is submitted to builder
 3. Builder creates docker image
 4. When triggered, runner execute docker image
