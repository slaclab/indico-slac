# https://docs.getindico.io/en/latest/installation/production/debian/apache/

# Based on Debian stable
FROM debian:stretch

MAINTAINER salnikov@slac.stanford.edu

ENV INDICO_VERSION="2.1.8"
ENV INDICO_DIR=/opt/indico
ENV INDICO_USER=indico
ENV INDICO_GROUP=indico
ENV INDICO_UID=1000
ENV INDICO_GID=1000

RUN apt-get update && \
    apt-get install -y uwsgi uwsgi-plugin-python && \
    apt-get install -y libjpeg62-turbo-dev && \
    apt-get install --assume-yes --no-install-recommends python-virtualenv && \
    apt-get install --assume-yes --no-install-recommends procps && \
    apt-get autoclean && \
    apt-get clean

# indico needs separate user
RUN groupadd --gid ${INDICO_GID} ${INDICO_GROUP} && \
    useradd -m --home-dir /home/${INDICO_USER} \
            --uid ${INDICO_UID} --gid ${INDICO_GID} \
            ${INDICO_USER} && \
    mkdir -p ${INDICO_DIR} && \
    chown ${INDICO_USER} ${INDICO_DIR}

# install indico from PyPI (and clean pip cache)
RUN su --login -c "cd /home/${INDICO_USER} && \
    python -m virtualenv indico-venv && \
    . ./indico-venv/bin/activate && \
    pip install --no-cache-dir -U pip setuptools && \
    pip install --no-cache-dir indico==${INDICO_VERSION} indico-plugins && \
    rm -rf .cache" \
    ${INDICO_USER}

USER ${INDICO_USER}

RUN mkdir -p ${INDICO_DIR}/data ${INDICO_DIR}/scratch

#
#  - scratch is folder for tmp, cache, and log
#  - data is for etc and archive
#
VOLUME ${INDICO_DIR}/data ${INDICO_DIR}/scratch

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["run"]
