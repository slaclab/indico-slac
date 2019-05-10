# Based on standard Postres image
FROM postgres:10

MAINTAINER salnikov@slac.stanford.edu

# copy the script to initialize indico database
COPY indico-initdb.sh /docker-entrypoint-initdb.d/
