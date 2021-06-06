#!/usr/bin/env bash

# INDICO_DIR and BACKUP_DIR must be set in environment

INDICO_CONFIG="$INDICO_DIR/etc/indico.conf"
LOG="$BACKUP_DIR/log"

# get database connection params from Indico config, sorry for messy URL parsing
parse_config() {
    vars=$(sed -n "s%SQLALCHEMY_DATABASE_URI *= ['\"]*postgres://\(.*\):\(.*\)@\(.*\)\(:\([0-9]+\)\)*/\(.*\)['\"]%export PGUSER=\1 PGPASSWORD=\2 PGHOST=\3 PGPORT=\5 PGDATABASE=\6%p" <$INDICO_CONFIG)
    eval $vars
}

# make full backup to a specified file
make_backup() {
    dst=$1
    pg_dump --format=c --file="$dst" $PGDATABASE
}

parse_config || exit 1

if [ "$1" = "backup" ]; then

    echo $(date +'%Y-%m-%d %H:%M:%S'): $* >> $LOG
    restore_file=${2:-${BACKUP_DIR}/indico.dump}
    make_backup $restore_file.tmp  && mv $restore_file.tmp $restore_file >> $LOG 2>&1

elif [ "$1" = "restore" ]; then

    echo $(date +'%Y-%m-%d %H:%M:%S'): $* >> $LOG
    restore_file=${2:-${BACKUP_DIR}/indico.dump}
    if [ ! -f "$restore_file" ]; then
        echo "Backup file $restore_file does not exist" >> $LOG
        echo "Backup file $restore_file does not exist" 1>&2
        exit 1
    fi
    dropdb --if-exists $PGDATABASE && \
        createdb --owner=$PGUSER $PGDATABASE && \
        pg_restore --dbname=$PGDATABASE $restore_file >> $LOG 2>&1

elif [ "$1" = "daily" -o "$1" = "weekly" -o "$1" = "monthly" ]; then

    echo $(date +'%Y-%m-%d %H:%M:%S'): $* >> $LOG

    keep=$2
    if [ "$1" = "weekly" ]; then
        if [ -n "$keep" ]; then
            keep=$((keep * 7 + 1))
        fi
    elif [ "$1" = "monthly" ]; then
        if [ -n "$keep" ]; then
            keep=$((keep * 31 + 1))
        fi
    fi

    # backup
    timestamp=$(date +'%Y%m%dT%H%M%S')
    backup_file=${BACKUP_DIR}/$1/indico-$timestamp.dump
    echo "$(date +'%Y-%m-%d %H:%M:%S'): backup to $backup_file" >> $LOG
    mkdir -p "${BACKUP_DIR}/$1" && make_backup "$backup_file" >> $LOG 2>&1

    # cleanup
    if [ -n "$keep" ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S'): cleanup in ${BACKUP_DIR}/$1, keep last $keep days" >> $LOG
        to_remove=$(find "${BACKUP_DIR}/$1" -name indico-*.dump -maxdepth 1 -mtime +${keep})
        for file in $to_remove; do
            echo $(date +'%Y-%m-%d %H:%M:%S'): removing old backup $file >> $LOG
            rm -f $file
        done
    fi

else
    echo "Unexpected command: $1" >&2
    exit 1
fi
