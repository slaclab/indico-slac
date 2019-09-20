# https://docs.getindico.io/en/latest/installation/production/debian/apache/

# Based on image which includes LaTeX
FROM fermented/indico-latex:latest

MAINTAINER salnikov@slac.stanford.edu

ENV INDICO_VERSION="2.2.2"
ENV INDICO_DIR=/opt/indico
ENV INDICO_USER=indico
ENV INDICO_GROUP=indico
ENV INDICO_UID=1000
ENV INDICO_GID=1000

RUN apt-get update && \
    apt-get install -y build-essential && \
    apt-get install -y uwsgi uwsgi-plugin-python && \
    apt-get install -y libjpeg62-turbo-dev && \
    apt-get install -y python-ldap && \
    apt-get install --assume-yes --no-install-recommends python-virtualenv && \
    apt-get install --assume-yes --no-install-recommends procps && \
    apt-get install --assume-yes --no-install-recommends python-dev && \
    apt-get install --assume-yes --no-install-recommends libpq-dev && \
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
    python -m virtualenv --system-site-packages indico-venv && \
    . ./indico-venv/bin/activate && \
    pip install --no-cache-dir -U pip setuptools && \
    pip install --no-cache-dir indico==${INDICO_VERSION} indico-plugins && \
    rm -rf .cache" \
    ${INDICO_USER}

# run setup script to setup things in /home/indico/indico but then move result to
# /home/indico/indico
COPY ./indico-wizard.py /home/${INDICO_USER}
RUN su --login -c "cd /home/${INDICO_USER} && \
    . ./indico-venv/bin/activate && \
    mkdir /home/${INDICO_USER}/indico && \
    python ./indico-wizard.py --root-path=/home/${INDICO_USER}/indico --dst-path=${INDICO_DIR}" \
    ${INDICO_USER}

COPY ./uwsgi-indico.ini /etc/uwsgi.ini

# make them writable so that when container runs with non-root user
# it can still create files (when volumes are not explicitly bound)
RUN mkdir -p ${INDICO_DIR}/scratch ${INDICO_DIR}/data ${INDICO_DIR}/web && \
    chmod go+w ${INDICO_DIR}/scratch ${INDICO_DIR}/data ${INDICO_DIR}/web

#
#  - scratch is folder for tmp, cache, and log
#  - web is folder for htdocs and assets
#  - data is for etc and archive
#
VOLUME ${INDICO_DIR}/scratch ${INDICO_DIR}/data ${INDICO_DIR}/web

# uwsgi port
EXPOSE 8008

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["run"]
