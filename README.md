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

Images are built locally and pushed to DockerHub
[indico4slac](https://hub.docker.com/orgs/indico4slac) organization,
instructions and configuration files in this repository use images from
DockerHub.


## Building images

Images are built with `latest` tag using the command:

    docker-compose -f docker-compose-build.yml build

and pushed to DockerHub with command:

    docker-compose -f docker-compose-build.yml push

Stable images should be tagged by `stable` tag, these images are normally used
for production running. To tag all `latest` images in DockerHub with `stable`
tag:

    ./make-image-tags.sh

To tag a specific image `latest` tag with some other tag:

    ./make-image-tags.sh -t 2.3.0 indico-worker

# User account

By default both indico containers (`indico-worker` and `indico-celery`) run
under the special user account defined in the image with UID=987 and GID=987.
All files and folders created by the containers are owned by this user,
including files on volumes that are mapped to a host file system. In practice
this means that those file should only be readable by `root` as group `987` is
not likely to exist on the host.

If it is desirable to have those files owned by an actual user account on the
host system (e.g. dedicated `indico` account) then one has to define a special
environment variable before starting containers. Variable name is
`INDICO_USER` and it has to contain UID and GID numbers separated by colon,
e.g.:

    export INDICO_USER=$(id -u indico):$(id -g indico)

Note that when `indico-worker` container starts without `INDICO_USER` it runs
initially as `root`. As `root` it changes ownership of the indico files on
exported volumes to UID=987 and GID=987 and then starts indico process with
the same UID and GID.


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

Here is the list commands to make all sub-folders:

    export INDICO_DIR=/opt/indico-docker
    sudo mkdir -p $INDICO_DIR $INDICO_DIR/backups $INDICO_DIR/ssl $INDICO_DIR/postgres $INDICO_DIR/log

If you plan to run indico containers under a non-default user ID on local
host, e.g. `indico` (by setting `INDICO_USER`, see below) then change
ownership of the created folders:

    sudo chown -R $(id -u indico).$(id -g indico) $INDICO_DIR

(`postgres` folder ownership will be changed later by postgres container).


## Database setup

On the very fist execution of `indico-db` container when database data folder
is empty it has to be passed few environment variables which define passwords
for a privileged database account, which is usually `postgres` (can be
changed if needed). The password is only used to connect to that account from
other containers, when executing `psql` from inside container password is not
used.

To start Postgres container for one-time initialization (if you want to run
container in foreground and omit `-d` option don't forget to add `--rm`
option or cleanup container after it stops):

    docker-compose run -d -e POSTGRES_PASSWORD=****** indico-db

One it is started you can connect to the server from container itself and
create indico database similarly to how it is explained in [Indico
Guide](https://docs.getindico.io/en/stable/installation/production/debian/nginx/#create-a-database),
check the container name from the output of `docker-compose run`:

    docker exec -ti indico-slac_indico-db_run_4108e9220799 psql -U postgres
    postgres=#
    -- and run these commands:
    CREATE ROLE indico WITH CREATEDB LOGIN PASSWORD 'indico-db-password';
    CREATE DATABASE indico WITH OWNER=indico;
    \connect indico
    CREATE EXTENSION unaccent;
    CREATE EXTENSION pg_trgm;
    \q

And stop database container:

    docker-compose down


## Worker setup

[indico-worker](indico-worker/README.md "indico-worker README") describes
steps needed to configure and initialize Indico worker container. These steps
include:
- Copying pre-defined configuration files to a volume on host
- Editing `indico.conf` file to configure it for local environment
- Running container with `indico db prepare` command to create database schema,
  or restoring a backup of PostgreSQL dump if migrating from previous version

First step is to generate default configuration file:

    export INDICO_USER=$(id -u indico):$(id -g indico)  # optional, see above
    export INDICO_TAG=stable  # or `latest` or any other tag
    docker-compose run --no-deps --rm indico-worker make-config

This will create `indico.conf` and `logging.yaml` in `$INDICO_DIR/etc/` folder
(and container will stop immediately). `indico.conf` has to be updated with
all necessary configuration changes, and in particular with a new database
password in `SQLALCHEMY_DATABASE_URI` parameter. `SMTP_SERVER` needs to point
to host node IP instead of `localhost`. After fixing configuration the
database schema needs to be created with this command:

    docker-compose run --rm indico-worker indico db prepare

or in case of migration from previous releases one can restore database backup:

    cp .../old-backup.dump  $INDICO_DIR/backups/indico.dump
    docker-compose run --rm indico-db-backup restore

followed by usual `indico db upgrade`:

    docker-compose run --rm indico-worker indico db upgrade
    docker-compose run --rm indico-worker indico db --all-plugins upgrade


## SSL setup for web service

`$INDICO_DIR/ssl` folder has to have indico certificate files (`indico.key`
and `indico.crt`) copied for httpd service. These have to be generated and
copied in a usual way. For testing one can create self-signed certificate:

    openssl req -x509 -nodes -newkey rsa:4096 -subj /CN=indico.slac.stanford.edu \
        -keyout $INDICO_DIR/ssl/indico.key -out $INDICO_DIR/ssl/indico.crt


# Regular deployment

After initial setup is complete `docker-compose` is used to orchestrate
execution of the whole set of containers. This needs a small number of
environment variables to be defined:
- `INDICO_TAG` - optional tag for docker images, default is to use `stable`
- `INDICO_DIR` - optional top-level directory name on host system, defaults to
  `/opt/indico-docker`
- `INDICO_USER` - optional UID and GID for container execution
- `INDICO_MON` - host and port for publishing monitoring information

This is the typical setup:

    # export INDICO_USER=$(id -u indico):$(id -g indico)  # optional, see above
    export INDICO_MON="134.79.129.138:25826"  # or something else
    export INDICO_TAG=stable  # or `latest`

and with this one can start whole thing by:

    docker-compose up -d

If only a subset of services is need, e.g. only running worker, database,
redis, and web server:

    docker-compose up -d indico-worker indico-httpd

To list running containers:

    docker-compose ps

And to check logs from specific service:

    docker-compose logs indico-worker

If any image is updated then to restart containers with new image:

    docker-compose up -d


## Indico version upgrade

When new version of Indico is released:

- at minimum update version number in `indico-worker/Dockerfile`, there may be
  other changes needed, check installation instructions
- build the whole shebang and push to DockerHub with the `latest` tag for each
  image:
```
    docker-compose -f docker-compose-build.yml build
    docker-compose -f docker-compose-build.yml push
```
- tag `indico-worker` with a new version tag and `stable` tag:
```
    ./make-image-tags.sh -t X.Y.Z indico-worker
    ./make-image-tags.sh -t stable indico-worker
```
- if other images changed it is easier to tag all of them with the `stable`
  tag:
```
    ./make-image-tags.sh
```
- restart whole thing using new `stable` tag:
```
    # export INDICO_USER=$(id -u indico):$(id -g daemon)  # optional, see above
    export INDICO_MON="134.79.129.138:25826"  # or something else
    docker-compose up -d
```


## Database backup and restore

`indico-db-backup` has couple of special commands to backup otr restore
database contents. Check [indico-db-backup README](indico-db-backup/README.md)
for details.
