# Based on Debian stable
FROM debian:stable

ENV INDICO_DIR=/opt/indico
ENV INDICO_MON=

# install collectd
RUN apt-get update && \
    apt-get install -y --no-install-recommends collectd \
            libyajl2 libcurl3-gnutls postgresql redis && \
    apt-get autoclean && \
    apt-get clean

COPY docker-entrypoint.sh collectd.conf /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["collectd"]
