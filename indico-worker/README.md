Indico worker image
===================

This image contains full Indico installation and it is used to run all Indico
jobs such as standard worker, Celery worker, and any indico sub-commands.

The build process for this image follows the installation instructions from
https://docs.getindico.io/en/latest/installation/. This includes running a
customized version of `indico setup wizard` script which generates default
configuration files. Obviously these configuration files need to be updated
for specific setup, the instructions for that are included below.

User account
------------

The image is built to run without USER (uses root UID=0 GID=0) but it will
not run with default root user, at least for Celery service. Container should
be started with `--user` option giving _both_ UID and GID, e.g.
`--user=$(id -u):$(id -g)` if you want to run with current used UID and GID.
Some of the container volumes need to be bound to a host file system and will
create files and directories on those volumes. The directories on a host
filesystem have to allow write access to the container user.

Volumes
-------

Indico worker uses several directories to store its data. Some data are
persistent (e.g. attachments) and temporary data can use significant space
so it makes sense to keep all that data on external volumes. The image
defines three volumes which re-arrage data directories normally stored
under `/opt/indico` (and `${INDICO_DIR}` normally corresponds to 
`/opt/indico` in the container):
- `${INDICO_DIR}/scratch` - for temporary data (`tmp`, `cache`, and `log`)
- `${INDICO_DIR}/data` - persistent data (`etc` and `archive`)
- `${INDICO_DIR}/web` - files served by web service

Normally `scratch` volume should be bound to some reasonably sized filesystem
on local host, it does not have to be shared. The `data` volume contains files
(configuration and attachments) which have to be shared across all Indico
workers, so this volume should be on a shared filesystem. `web` volume does
not need to be mapped outside container, it will only be used by
`indico-httpd` container. With all of that the volume options for `docker run`
will look like this:

    # -v option has format "<host dir>:<container dir>"
    docker run ... \
        --user $(id -u indico):$(id -g indico) \
        --volume /shared/files/indico-data:/opt/indico/data \
        --volume /local/files/indico-scratch:/opt/indico/scratch \
        fermented/indico-worker

(`fermented` is the current name of Docker Hub account hosting repositories).

Configuration
-------------

The very first step before anything can be done with the container is to
generate configuration files (`indico.conf` and `logging.yaml`). The image
already contains some default and unusable configuration so the steps to
generate usable config is to copy those files to a `data` volume and
edit the files. To copy the file to a `data` volume one needs to run
container with special `make-config` argument and bind `data` volume to a host
directory:

    mkdir /shared/files/indico-data
    docker run --rm \
        --user $(id -u indico):$(id -g indico) \
        --volume /shared/files/indico-data:/opt/indico/data \
        fermented/indico-worker make-config

This will create folder `/shared/files/indico-data/etc` and add `indico.conf`
and `logging.yaml` files. `make-config` will not overwrite existig files if
any file is already there, error message will be produced. `logging.yaml`
should be OK to use but `indico.conf` will need updates, comments in the file
and Indico documentation should provide enough guidance for that.

Once configuration is complete it can be used to run other Indico jobs, the
same `--volume` option should always be used for that.

Database setup
--------------

If database was never initialized the next step is to run `indico db prepare`
script. This obviously needs connection to database, so container with
database server will have to be running already and empty indico database has
to exist with corresponding account (defined in `indico.conf`). Assuming that
database container name is `indico-db` (this also corresponds to the name of
database server in config file) the command to initialize database is:

    docker run --rm \
        --user $(id -u indico):$(id -g indico) \
        --link indico-db \
        --volume /shared/files/indico-data:/opt/indico/data \
        --volume /local/files/indico-scratch:/opt/indico/scratch \
        fermented/indico-worker indico db prepare

Running worker
--------------

If container is launched without any argument (or with a single "run"
argument) then it starts a regular indico worker process using `uwsgi`
launcher/controller. Normally one also binds `scratch` volume so that
temporary files go to a separate filesystem. Usually it starts in a
detatched state and with a specific container name. Database server and
redis server have to be running too and they are linked:

    docker run --rm --detach \
        --name indico-worker \
        --user $(id -u indico):$(id -g indico) \
        --link indico-db \
        --link indico-redis \
        --volume /shared/files/indico-data:/opt/indico/data \
        --volume /local/files/indico-scratch:/opt/indico/scratch \
        fermented/indico-worker

It is good idea to also specify container restart policy via
`--restart=unless-stopped` parameter so that container is automatically
started when host boots.

Running Celery worker
---------------------

Celery worker job is started in the same way as regular worker but it needs an
explicit `celery` argument instead of `run` (and different container name):

    docker run --rm --detach \
        --name indico-celery \
        --user $(id -u indico):$(id -g indico) \
        --link indico-db \
        --link indico-redis \
        --volume /shared/files/indico-data:/opt/indico/data \
        --volume /local/files/indico-scratch:/opt/indico/scratch \
        fermented/indico-worker celery

There should be just one instance of Celery worker for the whole cluster.

Executing other indico commands
-------------------------------

One can also execute other indico commands in a way similar to the above
`indico db prepare`.
