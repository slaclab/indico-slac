#!/usr/bin/env bash

if [ "$1" = "backup" ]; then
    /backup.sh backup "$BACKUP_DIR/$RESTORE_FILE"
elif [ "$1" = "restore" ]; then
    /backup.sh restore "$BACKUP_DIR/$RESTORE_FILE"
elif [ "$1" = "cron" ]; then
    # make few cron entries and run cron daemon
    #     m h dom mon dow user  command
    echo "INDICO_DIR=$INDICO_DIR" >> /etc/crontab
    echo "BACKUP_DIR=$BACKUP_DIR" >> /etc/crontab
    echo "7 1 * * * root /backup.sh daily $BACKUP_KEEP_DAYS" >> /etc/crontab
    echo "7 2 * * 1 root /backup.sh weekly $BACKUP_KEEP_WEEKS" >> /etc/crontab
    echo "7 3 1 * * root /backup.sh monthly $BACKUP_KEEP_MONTHS" >> /etc/crontab
    # run cron in foreground
    cron -f -L 7
else
    /backup.sh "$@"
fi
