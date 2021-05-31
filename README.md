# Docker images for Indico

This repository contains scripts for building and deploying docker images for
running Indico (at SLAC). Everything is based on official Indico installation
instructions found at https://docs.getindico.io/en/latest/installation/.

## Images and containers

The whole thing is split into multiple services and containers:
- Database (Postgres) server, in `indico-db` folder
- Redis server, deployed via standard image from Docker Hub
- Image with LaTeX installation in `indico-latex` folder
- Image with Indico installation in `indico-worker` folder (based on LaTeX image)
- Web server image in `indico-httpd` folder

Images can be built locally, but they are also hosted on Docker Hub in
[fermented](https://hub.docker.com/u/fermented/) account, instructions
and configuration files in this repository use images from Docker Hub.

## Building images

Images are normally built by Docker Hub automated builds with `latest` tag
after updates to Github repository. Stable images are tagged by `stable` tag,
these images are normally used for production running. To tag all `latest`
images in DockerHub with `stable` tag:

    ./make-image-tags.sh

To tag a specific image with some other tag:

    ./make-image-tags.sh -t 2.3.0 indico-worker

Images can also be built locally, simplest is to use `docker-compose` script
`docker-compose-build.yml` which builds all local images using `latest` tag:

    docker-compose -f docker-compose-build.yml build

(local `latest` cag will be overwritten if you pull image from DockerHub).

## Initial configuration

Few things have to be configured with a special sequence of commands before
system is ready for automatic operations:
- database needs an initial configuration step which creates new accounts and
  passwords for them
- worker container needs its configuration to be adjusted for local
  environment
- worker container needs to be executed with specific options to initialize
  database schema

### Database setup

On the very fist execution of `indico-db` container when database data folder
is empty it has to be passed few environment variables which define passwords
for database accounts and optionally name and account of Indico database. Look
at [indico-db](indico-db/README.md "indico-db README") for description. After
this initialization step leave container running as it will be used by the
worker initialization steps.

### Worker setup

[indico-worker](indico-worker/README.md "indico-worker README") describes
steps needed to configure and initialize Indico worker container. These steps
iclude:
- Copying pre-defined configuration files to a volume on host
- Editing `indico.conf` file to configure it for local environment
- Running container with `indico db prepare` command to create database schema

## Deployment

### Initial setup

First step is to make all persistent folders on host filesystem to keep the
data used by all services. We use `/opt/indico/docker` as the root for all
folders (but this can be changed), here is the list commands to make all
sub-folders and assign correct ownership

    DATA=/opt/indico/docker
    sudo mkdir -p $DATA/data $DATA/backups $DATA/scratch $DATA/ssl
    sudo chown -R indico.indico $DATA
    sudo mkdir -p $DATA/postgres
    sudo chown -R postgres.postgres $DATA

(this assumes that users and groups `indico.indico` and `postgres.postgres`
exist on host OS, they can be changed to any other UID/GID).

$DATA/ssl folder has to have indico certificate files (`indico.key` and
`indico.crt`) copied for httpd service.

### Running individual containers

To deploy indico all containers need to be started in the right order,
properly chaining them and providing volume bindings. Containers that have to
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

### Using doocker-compose

Easier way to deploy everything at once is to use `docker-compose`
orchestration scripts. There is a `docker-compose.yml` scripts in the top
directory which defines all services. The YAML file may need to be copied and
modified to a specific environment as it contains paths of the host folders
bound to image volumes.

The orchestration script needs two environment variables to be set before
starting containers. `WORKER_USER` provides UIG:GID pair for the user in
worker containers, e.g.:

    export WORKER_USER=$(id -u indico):$(id -g indico)

and `POSTGRES_USER` which makes similar UID:GID for Postgres service:

    export POSTGRES_USER=$(id -u postgres):$(id -g postgres)

Any other suitable user name that exist on host OS can be used but folder
protection needs to be consistent with the user IDs.

A `INDICO_TAG` variable can be set to a tag name to be used instead of default
`stable` tag.

To run the whole thing, e.g. using `latest` tag:

    INDICO_TAG=latest docker-compose up -d

To list running containers:

    docker-compose ps

