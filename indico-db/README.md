
Image for Indico Postgres
=========================

Right now this is just a standard Postgres image with additional one-time
script to add indico database and account. In the future it will be replaced
with some other high-availability system.

The script that creates indico account in database runs only once when
database is initialized, for that to happen the data directory should be
empty initally empty. It is better to have data directory on external
persistent volume so one has to pass corresponding option to "docker run".
Passwords for `postgres` (database super-user) and indico account are
specified on the command line at database initilaization time. So very
first time when one runs container the command line will look like this
(`indico-db` name is just an example, one can use any other name):

    # create new forder for database store
    mkdir $DATA/postgres
    # start container and crate database
    docker run --rm -d --name indico-db \
        -e POSTGRES_PASSWORD=secret-pg \
        -e INDICO_PASSWORD=secret-indico \
        -v $HOME/docker/volumes/postgres:/var/lib/postgresql/data \
        indico-db:stable
    # run indico container and iitialize database
    #   docker run ......
    docker stop indico-db

It is also possible (a advisable) to avoid specifying passwords on a
command line and instead read them from file:

    docker run --rm -d --name indico-db \
        -e POSTGRES_PASSWORD_FILE=./secret-pg.txt \
        -e INDICO_PASSWORD_FILE=./secret-indico.txt \
        -v $HOME/docker/volumes/postgres:/var/lib/postgresql/data \
        indico-db:stable

There are few other variables that can be used to change indico account name
or database name, here is the list of indico-specific variables that this
image defines:
- `INDICO_USER` - name for Postgres account (default is `indico`)
- `INDICO_DB` - database name (default is `$INDICO_USER`)
- `INDICO_PASSWORD` - password for indico account (`INDICO_PASSWORD_FILE`
  can be used instead)

There is also a bunch of general Postgres-related variables defined by parent
image, check https://hub.docker.com/_/postgres for details.

After database is created there is no need to pass initialization variables
to container, on subsequent invocations the command will look like:

    docker run --rm -d --name indico-db \
        -v $HOME/docker/volumes/postgres:/var/lib/postgresql/data \
        indico-db:stable
