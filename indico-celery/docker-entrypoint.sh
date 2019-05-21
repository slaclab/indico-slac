#!/usr/bin/env bash

CONFIG_FILES="$INDICO_DIR/data/etc/indico.conf $INDICO_DIR/data/etc/logging.yaml"

# setup indico
export INDICO_CONFIG=$INDICO_DIR/data/etc/indico.conf
. /home/${INDICO_USER}/indico-venv/bin/activate

# make folders if they don't exist yet
mkdir -p ${INDICO_DIR}/scratch/log
mkdir -p ${INDICO_DIR}/scratch/tmp

# for all other options we need config files
if [ "$1" = "run" ]; then
    for f in $CONFIG_FILES; do
        if [ ! -f "$f" ]; then
            cat >&2 <<EOWARN
***************************************************************************
WARNING: Configuration files are missing. Please run container with
         "make-config" argument and update configuration files.
         $CONFIG_FILES
***************************************************************************
EOWARN
            exit 2
        fi
    done
    exec indico celery worker -B
else
    exec "$@"
fi
