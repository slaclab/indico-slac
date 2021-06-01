# Docker images for Indico

This repository contains scripts for building and deploying docker images for
running Indico (at SLAC). Everything is based on official Indico installation
instructions found at https://docs.getindico.io/en/latest/installation/.

## Images and containers

The whole thing is split into multiple services and containers:
- Database (Postgres) server, deployed via standard image from DockerHub
- Redis server, deployed via standard image from DockerHub
- Image with Indico installation in `indico-worker` folder
- Web server image in `indico-httpd` folder
- Image to manage backups of Indico database in `indico-db-backup` folder
- Image to collect monitoring stats in `indico-collectd` folder

Images can be built locally, but they are also hosted on Docker Hub in
[fermented](https://hub.docker.com/u/fermented/) account, instructions
and configuration files in this repository use images from DockerHub.

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

(local `latest` tag will be overwritten if you pull image from DockerHub).

# Initial configuration

Few things have to be configured with a special sequence of commands before
system is ready for automatic operations:
- creating directory structure
- database initial configuration step which creates new accounts and
  passwords for them
- worker container configuration to be adjusted for local environment
- worker container executed with specific options to initialize database schema

## Creating directories

First step is to make all persistent folders on host filesystem to keep the
data used by all services. We use `/opt/indico-docker` as the root for all
folders (but this can be changed) and use a local `indico` account for
ownership.

Here is the list commands to make all sub-folders and assign correct ownership:

    export INDICO_DIR=/opt/indico-docker
    sudo mkdir -p $INDICO_DIR/data $INDICO_DIR/backups $INDICO_DIR/scratch $INDICO_DIR/ssl $INDICO_DIR/postgres
    sudo chown -R indico.indico $INDICO_DIR

## Create docker network

This is normally created by `docker-compose` but for one-time initialization
we need to do it manually:

    docker network create indico-net

## Database setup

On the very fist execution of `indico-db` container when database data folder
is empty it has to be passed few environment variables which define passwords
for a priviledged database account, which is usually `postgres` (can be
changed if needed). The password is only used to connect to that account from
other containers, when executing `psql` from inside container password is not
used.

To start container for one-time initialization (assuming Posgres v12):

    export INDICO_USER=$(id -u indico):$(id -g indico)
    docker run -d --rm --name indico-db --user $INDICO_USER \
        -e POSTGRES_PASSWORD=mysecretpassword \
        --network indico-net  -v $INDICO_DIR/postgres:/var/lib/postgresql/data \
        postgres:12

One it is started you can connect to the server from container itself and
create indico database similarly to how it is explained in [Indico
Guide](https://docs.getindico.io/en/stable/installation/production/debian/nginx/#create-a-database):

    docker exec -ti indico-db psql -U postgres
    postgres=#
    -- and run these commands:
    CREATE ROLE indico WITH CREATEDB LOGIN PASSWORD 'indico-db-password';
    CREATE DATABASE indico WITH OWNER=indico;
    \connect indico
    CREATE EXTENSION unaccent;
    CREATE EXTENSION pg_trgm;
    \q

After this initialization step leave container running as it will be used by
the worker initialization steps.

## Worker setup

[indico-worker](indico-worker/README.md "indico-worker README") describes
steps needed to configure and initialize Indico worker container. These steps
include:
- Copying pre-defined configuration files to a volume on host
- Editing `indico.conf` file to configure it for local environment
- Running container with `indico db prepare` command to create database schema

Briefly this is what needs to be done while `indico-db` container is still
running. First step is to generate default configuration file:

    docker run --rm --user $INDICO_USER \
        --volume $INDICO_DIR/data:/opt/indico/data \
        fermented/indico-worker make-config

This will create `indico.conf` and `logging.yaml` in `$INDICO_DIR/data/etc/`
folder (and container will stop immediately). `indico.conf` has to be updated
with all necessary configuration changes, and in particular with a new
database password in `SQLALCHEMY_DATABASE_URI` parameter. After fixing
configuration thge database schema needs to be created with this command:

    docker run --rm --user $INDICO_USER \
        --network indico-net \
        --volume $INDICO_DIR/data:/opt/indico/data \
        --volume $INDICO_DIR/scratch:/opt/indico/scratch \
        fermented/indico-worker indico db prepare

After this finishes with success the `indico-db` container should be stopped:

    docker stop indico-db

## SSL setup for web service

$DATA/ssl folder has to have indico certificate files (`indico.key` and
`indico.crt`) copied for httpd service. This have to be generated and copied
in a usual way. For testing one can create self-signed certificate:

    openssl req -x509 -nodes -newkey rsa:4096 -subj /CN=indico.slac.stanford.edu \
        -keyout $INDICO_DIR/ssl//indico.key -out $INDICO_DIR/ssl/indico.crt



# Deployment

After initial setup is complete we use `docker-compose` for orchestrating
execution of the whole set of containers. This needs small number of
environment variables to be defined:
- `INDICO_TAG` - optional tag for docker images, default is to use `stable`
- `INDICO_DIR` - optional top-level directory name on host system
- `INDICO_USER` which defines UID and GID for container execution
- `INDICO_MON` - host and port for publishing monitoring information

This is the typical setup:

    export INDICO_USER=$(id -u indico):$(id -g indico)
    export INDICO_MON="134.79.129.138:25826"
    export INDICO_TAG=latest

and with this one can start whole thing by:

    docker-compose up -d

To list running containers:

    docker-compose ps

And to check logs from specific service:

    docker-compose logs indico-worker

If any image is updated then to restart containers with new image:

    docker-compose up -d
