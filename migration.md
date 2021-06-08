Migrating standard Indico install to Docker (in 11 easy steps)
==============================================================

Notes collected during the migration process of indico01 machine.

indico01 is our backup machine in case production one (indico02) fails for
some reason. Its setup is identical to indico02 and we regularly copy databse
backups from indico02 and restore them to indico01 postgresql server, there
are scripts in `/opt/indico/custom/backup` folder that deal with that.

As of today (2021-06-01) we have indico 2.3.5 installed with in venv. We are
running everything as regular systemd services:
- `uwsgi` which runs Indico worker proceses
  (/etc/systemd/system/uwsgi.service.d)
- `celery` runs as separate systemd service
  (/etc/systemd/system/indico-celery.service)
- `redis` server
- postgres server (ancient 9.6 from standard CentOS7 repo)
- `apache` as `uwsgi` frontend
- `collectd` for monitoring (only on indico02)

Everything is configured according to [Indico
guide](https://docs.getindico.io/en/latest/installation/production/centos/apache/).

Important data that needs to be preserved in a new system is:
- Database obviously, need to dump full contents of `indico` database and
  restore it in a new server.
- all attachemnts, these are in `/opt/indico/archive` directory
- configuration in `/opt/indico/etc`
- some customizations in `/opt/indico/custom`


Step 0. Pre-requsites
---------------------

To run docker containers your account has to be in a `docker` group, if it is
not then do this once:

    sudo usermod -a -G docker $USER

(and you need to close current shell and start a new one).

For this migration we use `stable` tag of the relevant docker images, they
should exist in DockerHub already. If something different is needed then
relevant DockerHub tags needs to be created/updated.


Step 1. Shut it down
--------------------

To stop all services and preserve data.

Stop `celery` (this should not be running on indico01, but will be running on
indico02) and disable it, run as root:

    systemctl stop indico-celery
    systemctl disable indico-celery

Same for uwsgi and redis:

    systemctl stop uwsgi
    systemctl disable uwsgi
    systemctl stop redis
    systemctl disable redis

Apache seems to be dead on indico01, but if it runs it needs to be stoppped
too:

    systemctl stop httpd
    systemctl disable httpd

While postgres is still running dump the contents of indico database (this is
not needed on indico01 because we use backup from indico02), again as root:

    /opt/indico/custom/backup/slac-backup-indico

the result will be in `/opt/indico/custom/backup/slac-indico-backup.dump`.
Then stop postgres too:

    systemctl stop postgresql-9.6
    systemctl disable postgresql-9.6

Done.


Step 2. Create folders for new setup
------------------------------------

For new setup I wanted to have it all in a disjoint set of folders, in
`/opt/indico-docker`. [README](./README.md) explains how to make new set of
folders which are owned by `indico` account, here is the gist:

    export INDICO_DIR=/opt/indico-docker
    sudo mkdir -p $INDICO_DIR $INDICO_DIR/backups $INDICO_DIR/ssl $INDICO_DIR/postgres
    sudo chown -R indico.daemon $INDICO_DIR

`INDICO_DIR` is used in the examples below, if you switch to new shell then
define the variable again. Group `daemon` is used because Apache container
runs using `daemon` UID/GID.


Step 3. Clone `indico-slac` package
-----------------------------------

All docker stuff is in a `indico-slac` package on github, you should clone it
as yourself:

    cd $HOME
    git clone git@github.com:andy-slac/indico-slac.git
    cd indico-slac

And check that images are accessible, can be downloaded:

    docker-compose pull


Step 4. Create Postgres database for indico
-------------------------------------------

Next step is to re-create indico database in its empty state, for that we need
to start a database contaner with a special variable which specifies a
password for the `postgres` account (replace asterisks with actual password):

    export INDICO_USER=$(id -u indico):$(id -g daemon)
    docker-compose run -d -e POSTGRES_PASSWORD=****** indico-db

Check the name of the running container, above `run` command should print it
but you can also do:

    $ docker-compose ps
               Name                         Command              State    Ports
    -----------------------------------------------------------------------------
    indicoslac_indico-db_run_1   docker-entrypoint.sh postgres   Up      5432/tcp

then connect to the container and run `psql` to create indico user and
database, need to specify password:

    $ docker exec -ti indicoslac_indico-db_run_1 /bin/bash
    # and in this shell run:

    export PGUSER=postgres
    createuser --createdb --pwprompt indico
    createdb -O indico indico
    psql indico -c "CREATE EXTENSION unaccent; CREATE EXTENSION pg_trgm;"
    exit

"root" role may be needed for monitoring, will create it later.

And stop database container:

    docker-compose down


Step 5. Generate indico config files
------------------------------------

This may be skipped and we can copy/modify config files directly, but I wanted
to run this as an exersize and override files:

    docker-compose run --no-deps --rm indico-worker make-config

which creates two config files in `/opt/indico-docker/etc`, `indico.conf`
and `logging.yaml`. Latter should be OK already, but `indico.conf` needs
updates. I cannot copy existing `indico.conf` because some options are
different so merge of the two configs is needed.

Few specific configuration parameters:
- `SQLALCHEMY_DATABASE_URI` needs a host name and a password, e.g.
  `'postgres://indico:password@indico-db/indico'`
- `SMTP_SERVER` has to point to `smtpout.slac.stanford.edu`, port 25.
- `XELATEX_PATH` has to be commented out, it is in standard location.
- for testing onle `BASE_URL` needs to point to actual host name
  (`https://indico01.slac.stanford.edu`)


Step 6. Make database schema
----------------------------

After fixing configuration thge database schema needs to be created with this
command:

    docker-compose run --rm indico-worker indico db prepare


Step 7. Restore database backup
-------------------------------

Copy backup to a known location and run restore command:

    sudo cp /opt/indico/custom/backup/slac-indico-backup.dump /opt/indico-docker/backups/indico.dump
    sudo chown indico.daemon /opt/indico-docker/backups/indico.dump
    docker-compose run --rm indico-db-backup restore

`/opt/indico-docker/backups/log` shows errors abot "root" account, this are
because I have not made "root" yet. There are some other messages, this could
be because we resore v9.6 backup into v12 databse. Anyways, data is loaded OK.


Step 8. SSL certs
-----------------

Copy SSL certificates to new location:

    sudo cp /etc/pki/tls/private/indico.key /opt/indico-docker/ssl/indico.key
    sudo cp /etc/pki/tls/certs/indico_slac_stanford_edu_cert.cer /opt/indico-docker/ssl/indico.crt


Step 9. Copy attachemnts
------------------------

Attachemnt files have to be copied to their new location:

    sudo rsync -a /opt/indico/archive  /opt/indico-docker/

That failed because `/opt` became full. For now I'm adding it as a volume
pointing to `/opt/indico/archive` on host.


Step 10. Copy customizations
----------------------------

Few files that are in `/opt/indico/custom` need to be copied:

    sudo mkdir -p $INDICO_DIR/custom
    sudo cp -pR /opt/indico/custom/files /opt/indico/custom/templates $INDICO_DIR/custom/
    sudo chown -R indico.daemon $INDICO_DIR/custom


Step 11. Start all services
---------------------------

First stop all runnig stuff (redis, postgres are probably running):

    docker-compose down

Then setup all envvars and start again, but do not run celery on indico01:

    export INDICO_USER=$(id -u indico):$(id -g daemon)
    export INDICO_MON="134.79.129.138:25826"
    docker-compose up -d indico-worker indico-httpd indico-db-backup indico-collectd
