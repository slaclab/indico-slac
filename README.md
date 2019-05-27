# Docker images for Indico

This repository contains scripts for building and deploying docker images for
running Indico (at SLAC). Everything is based on official Indico installation
instructions found at https://docs.getindico.io/en/latest/installation/.

## Images and containers

The whole thing is split into multiple services and containers:
- Database (Postgres) server, in `indico-db` folder
- Redis server, deployed via standard image from Docker Hub
- Image with LaTeX installation in `indico-latex` folder
- Image with Indico installation in `indico-worker` folder
- Web server image in `indico-httpd` folder

Images can be built locally, but they are also hosted on Docker Hub in
[fermented](https://hub.docker.com/u/fermented/) account, instructions
and configuration files in this repository use images from Docker Hub.

## Building images

Images are normally built by Docker Hub automated builds with `latest` tag
after updates to Github repository. Stable images are tagged by `stable` tag,
these images are normally used for production running.

Images can also be built locally, simplest is to use `docker-compose` script
`docker-compose-build.yml` which builds all local images:

    docker-compose -f docker-compose-build.yml build

## Initial configuration

Few things have to be configured with a special sequence of commands before
system is ready for automatic operations:
- database needs an initial configuration step which creates new accounts and
  passwords for them
- worker container needs its configuration to be adjusted for local
  environment
- worker container needs to be executed with specific options to intialize
  database schema

### Database setup

On the very fist execution of `indico-db` container when database data folder
is empty it has to be passed few environment variables which define passwords
for database accounts and optionally name and account of Indico database. Look
at [indico-db](indico-db/README.md "indico-db README") for description. After
this initialization step leave container running as it will be used by the
worker intialization steps.

### Worker setup

[indico-worker](indico-worker/README.md "indico-worker README") describes
steps needed to configure and initialize Indico worker container. These steps
iclude:
- Copying pre-defined configuration files to a volume on host
- Editing `indico.conf` file to configure it for local environment
- Running container with `indico db prepare` command to create database schema

## Deployment

To deploy indico all containers need to be started in the right order,
properly chaning them and providing volume bindings. Containers that have to
be started are:
- `indico-redis` - starts from standard [Redis image](https://hub.docker.com/_/redis)
- `indico-db` - from `fermented/indico-db`
- `indico-worker` - from `fermented/indico-worker`
- `indico-celery` - from `fermented/indico-worker`, only one container for the
  whole cluster
- `indico-httpd` - from `fermented/indico-httpd`

Redis container should start with the command:

    docker run --detach --rm redis:alpine

for all other containers consult corresponding folder for description of command
line options.

Easier way to deploy everything at once is to use `docker-compose` orchestration
scripts. There are two of these scripts in the top directory -- 
`docker-compose.yml` and `docker-compose-celery.yml`. Former contains all
services except for `indico-celery`, latter adds `indico-celery` to the set.
There should be only one instance of `indico-celery` service in the whole
cluster, so `docker-compose-celery.yml` should be used on only one host,
all other hosts shoud use `docker-compose.yml`.

The files have to be copied and modified to a specific environment as they
contain paths of the host folders bound to image volumes.
