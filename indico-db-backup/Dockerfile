# Based on standard Postres image
FROM postgres:10

MAINTAINER salnikov@slac.stanford.edu

ENV INDICO_DIR=/opt/indico
ENV BACKUP_DIR=/backups
ENV BACKUP_KEEP_DAYS 7
ENV BACKUP_KEEP_WEEKS 5
ENV BACKUP_KEEP_MONTHS 6
ENV RESTORE_FILE=indico.dump

# install cron
# RUN apt-get update && \
#     apt-get install --assume-yes --no-install-recommends cron && \
#     apt-get autoclean && \
#     apt-get clean

VOLUME ${BACKUP_DIR}

COPY docker-entrypoint.sh backup.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["cron"]
