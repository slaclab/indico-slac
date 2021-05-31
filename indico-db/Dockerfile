# Based on standard Postgres image
FROM postgres:12

LABEL edu.stanford.slac.indico.authors="salnikov@slac.stanford.edu"

# copy the script to initialize indico database
COPY indico-initdb.sh /docker-entrypoint-initdb.d/
