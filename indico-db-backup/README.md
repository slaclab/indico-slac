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

Normally execution of container is orchestrated by `docker-compose` together
with other Indico containers, see `README.md` at the top-level folder.

To run one-shot backup job just pass `backup` argument:

    docker-compose run --rm indico-db-backup backup

One can also provide different path for backup file, remember that path is
inside container:

    docker-compose run --rm indico-db-backup backup /backups/special.dump

To run one-shot restore job just pass `restore` argument, make sure that you
have right file at `/opt/indico-docker/backups/indico.dump` location:

    docker-compose run --rm indico-db-backup restore

Or to to restore from a specific file:

    docker-compose run --rm indico-db-backup restore /backups/special.dump
