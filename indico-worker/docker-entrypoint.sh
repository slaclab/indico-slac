#!/usr/bin/env bash

CONFIG_FILES="$INDICO_DIR/etc/indico.conf $INDICO_DIR/etc/logging.yaml"

# generate configuration
if [ "$1" = "make-config" ]; then
    for f in $CONFIG_FILES; do
        if [ -f "$f" ]; then
            cat >&2 <<EOWARN
***************************************************************************
WARNING: Configuration files exist and will not be overwritten. Remove or
         rename files if you want it replaced with default configuration:
         $CONFIG_FILES
***************************************************************************
EOWARN
            exit 2
        fi
    done
    mkdir -p $INDICO_DIR/etc
    cp /home/${INDICO_USER}/indico/etc/* $INDICO_DIR/etc/
    exit
fi

# setup indico
export INDICO_CONFIG=$INDICO_DIR/etc/indico.conf
. /home/${INDICO_USER}/indico-venv/bin/activate

# make folders if they don't exist yet
mkdir -p ${INDICO_DIR}/etc ${INDICO_DIR}/archive
mkdir -p ${INDICO_DIR}/log ${INDICO_DIR}/tmp ${INDICO_DIR}/cache

# for regular options we need config files
if [ "$1" = "run" -o "$1" = "celery" ]; then
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
fi

if [ "$1" = "run" ]; then
    # populate web/ folder
    mkdir -p ${INDICO_DIR}/web
    cp -rL --preserve=all /home/${INDICO_USER}/indico/web/static ${INDICO_DIR}/web

    exec /usr/bin/uwsgi --ini /etc/uwsgi.ini
elif [ "$1" = "celery" ]; then
    exec indico celery worker -B
else
    exec "$@"
fi
