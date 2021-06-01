#!/usr/bin/env bash

# get database connection params from Indico config, sorry for messy URL parsing
parse_config() {
    vars=$(sed -n "s%SQLALCHEMY_DATABASE_URI *= ['\"]*postgres://\(.*\):\(.*\)@\(.*\)\(:\([0-9]+\)\)*/\(.*\)['\"]%export PGUSER=\1 PGPASSWORD=\2 PGHOST=\3 PGPORT=\5 PGDATABASE=\6%p" <"$1")
    eval $vars
}

if [ "$1" = "collectd" ]; then

    if [ -z "$INDICO_MON" ]; then

        # nothing to do just sit there
        echo "WARNING: INDICO_MON envvar is empty, nothing to do"
        sleep 1000000000

    else

        IFS=: read host port <<< $INDICO_MON
        parse_config "$INDICO_DIR/data/etc/indico.conf"

        sed \
            -e "s:INDICO_DIR:$INDICO_DIR:g" \
            -e "s/INDICO_MON_HOST/$host/g" \
            -e "s/INDICO_MON_PORT/$port/g" \
            -e "s/PGHOST/$PGHOST/g" \
            -e "s/PGPORT/$PGPORT/g" \
            -e "s/PGUSER/$PGUSER/g" \
            -e "s/PGPASSWORD/$PGPASSWORD/g" \
            -e "s/PGDATABASE/$PGDATABASE/g" \
            < /collectd.conf > /tmp/collectd.conf

        exec collectd -C /tmp/collectd.conf -f

    fi

else
    exec "$@"
fi
