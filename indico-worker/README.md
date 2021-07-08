Indico worker image
===================

This image contains full Indico installation and it is used to run all Indico
jobs such as standard worker, Celery worker, and any indico sub-commands.

The build process for this image follows the installation instructions from
https://docs.getindico.io/en/latest/installation/. This includes running a
customized version of `indico setup wizard` script which generates default
configuration files. Obviously these configuration files need to be updated
for specific setup, the instructions for that are included below.

Differences in configuration compared to Indico instructions:
- we handle X-SendFile in uwsgi rather than apache, uwsgi config file has
  few additional options for that

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
persistent (e.g. attachments) and temporary data can use significant space so
it makes sense to keep all that data on external volumes. Presently the image
defines single volume `/opt/indico` that should be bound to a reasonably large
storage on host. The volume option for `docker run` will look like this:

    # -v option has format "<host dir>:<container dir>"
    docker run ... \
        --user $(id -u indico):$(id -g indico) \
        --volume /opt/indico-docker:/opt/indico \
        indico4slac/indico-worker

(`indico4slac` is the current name of Docker Hub organization hosting
repositories).

Setup
-----

Top-level `README.md` contains detailed instructions for using
`docker-compose` to orchestrate initial setup and regular execution of the
indico containers.

Executing other indico commands
-------------------------------

One can also execute other indico commands using either `docker-compose exec`
on a running container or `docker-compose run` to execute commands in a new
container:

    docker-compose exec indico-worker /bin/bash
    # --- in container
    $ . /home/indico/indico-venv/bin/activate
    $ export INDICO_CONFIG=/opt/indico/etc/indico.conf
    $ indico shell
    Indico v2.3.5 is ready for your commands
    In [1]:

or:

    docker-compose run --rm indico-worker indico shell
    Indico v2.3.5 is ready for your commands
    In [1]:
