Image for Indico database backup
================================

This image is based on a standard Postgres image and it runs a cron service
which triggers daily/weekly/monthly backups to an external volume. The
container needs access to regular database container (`indico-db`) so it needs
to be on the same network, which is typically named `indico-net`. The
connection parameters for Indico database are parsed from Indico (SQLAlchemy)
connection string which is defined in `indico.conf` configuration file, so
volume that holds that file has to be bound to the image, either via
`--volumes-from=indico-worker` option or `--volume` option (latter is
preferred as it does not need dependency in `indico-worker` container).

In standard mode when started without arguments (or with `cron` argument)
container runs cron daemon with three pre-defined schedules - daily, weekly,
and monthly. On each execution of a backup job the full backup of Indico is
made and saved in a separate directory (e.g. `/backups/daily`). Backups are
given unique file name with a current timestamp, e.g.
`indico-20190603T074619.dump`. Older backups are cleaned, keeping a configured
number of backups in each folder schedule.

Container can also be run with non-default options which changes its behavior.
With `backup` argument it will run a single backup job and will store its
output in `/backups/indico.dump` file (overwriting existing file). With
`restore` argument it will restore database from `/backups/indico.dump`
file (removing existing database contents first). Container will stop after
running these one-shot actions.

Example of running container using regular cron job

    docker run --rm --detach \
        --name indico-db-backup \
        --network indico-net \
        -v /opt/indico-docker/data:/opt/indico/data \
        -v /opt/indico-docker/backups:/backups \
        fermented/indico-db-backup:stable

To run one-shot backup job just pass `backup` argument:

    docker run --rm \
        --network indico-net \
        -v /opt/indico-docker/data:/opt/indico/data \
        -v /opt/indico-docker/backups:/backups \
        fermented/indico-db-backup:stable \
        backup

To run one-shot restore job just pass `restore` argument, make sure that you
have right file at `/opt/indico-docker/backups/indico.dump` location:

    docker run --rm \
        --network indico-net \
        -v /opt/indico-docker/data:/opt/indico/data \
        -v /opt/indico-docker/backups:/backups \
        fermented/indico-db-backup:stable \
        restore
