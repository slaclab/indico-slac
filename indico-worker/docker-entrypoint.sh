#!/usr/bin/env bash

# setup indico
export INDICO_CONFIG=$INDICO_DIR/etc/indico.conf
. /home/${INDICO_USER}/indico-venv/bin/activate

CONFIG_FILES="$INDICO_DIR/etc/indico.conf $INDICO_DIR/etc/logging.yaml"

# generate configuration
make_configs() {
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
}

# make folders if they don't exist yet
make_folders() {
    folders="archive cache etc log tmp"
    for folder in $folders; do
        mkdir -p ${INDICO_DIR}/${folder}
    done
    # if running as root make sure that all files belong to indico user
    if [ "$(id -u)" = "0" ]; then
        for folder in $folders; do
            chown -R ${INDICO_UID}:${INDICO_GID} ${INDICO_DIR}/${folder}
        done
    fi
}

check_configs() {
    # for regular options we need config files
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
}

if [ "$(id -u)" = "0" ]; then
    __gosu="gosu ${INDICO_UID}:${INDICO_GID}"
fi

if [ "$1" = "make-config" ]; then
    make_configs
elif [ "$1" = "run" ]; then
    make_folders
    check_configs
    exec ${__gosu} /home/${INDICO_USER}/indico-venv/bin/uwsgi --ini /etc/uwsgi.ini
elif [ "$1" = "celery" ]; then
    check_configs
    if [ "$(id -u)" != "0" ]; then
        if ! getent group $(id -g) 2>/dev/null; then
            # celery fails if GID does not correspond to real group name,
            # workaround is to specify C_FORCE_ROOT.
            export C_FORCE_ROOT=Y
        fi
    fi
    exec ${__gosu} indico celery worker -B
else
    exec "$@"
fi
