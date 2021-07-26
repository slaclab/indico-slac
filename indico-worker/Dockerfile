# https://docs.getindico.io/en/latest/installation/production/debian/apache/

# indico3 needs Python 3.9, instead of building is from scratch based
# on installation istructions we use python-3.9 image and add necessary
# stuff to it
FROM python:3.9-buster

LABEL edu.stanford.slac.indico.authors="salnikov@slac.stanford.edu"

ENV INDICO_VERSION="3.0"
# empty string for latest indico-plugins compatible with INDICO_VERSION
ENV INDICO_PLUGINS_VERSION=""
ENV INDICO_DIR=/opt/indico
ENV INDICO_USER=indico
ENV INDICO_GROUP=indico
ENV INDICO_UID=1000
ENV INDICO_GID=1000

# need latex installed
RUN apt-get update && \
    apt-get install -y libfontconfig1 ghostscript && \
    apt-get install -y --no-install-recommends texlive-xetex && \
    apt-get autoclean && \
    apt-get clean

RUN apt-get update && \
    apt-get install -y build-essential && \
    apt-get install -y uwsgi uwsgi-plugin-python && \
    apt-get install -y libjpeg62-turbo-dev && \
    apt-get install -y --no-install-recommends procps && \
    apt-get install -y --no-install-recommends libpq-dev && \
    apt-get install -y --no-install-recommends libldap2-dev libsasl2-dev libssl-dev  && \
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
    python -m venv --upgrade-deps --prompt indico indico-venv && \
    . ./indico-venv/bin/activate && \
    pip install --no-cache-dir wheel uwsgi && \
    pip install --no-cache-dir python-ldap && \
    pip install --no-cache-dir indico==${INDICO_VERSION} \
            indico-plugins${INDICO_PLUGINS_VERSION:+==$INDICO_PLUGINS_VERSION} && \
    rm -rf .cache" \
    ${INDICO_USER}

# run setup script to setup things in /home/indico/indico but then move result to
# /opt/indico
COPY ./indico-wizard.py /home/${INDICO_USER}
RUN su --login -c "cd /home/${INDICO_USER} && \
    . ./indico-venv/bin/activate && \
    mkdir /home/${INDICO_USER}/indico && \
    python ./indico-wizard.py --root-path=/home/${INDICO_USER}/indico --dst-path=${INDICO_DIR}" \
    ${INDICO_USER}

COPY ./uwsgi-indico.ini /etc/uwsgi.ini

# make them writable so that when container runs with non-root user
# it can still create files (when volumes are not explicitly bound)
RUN mkdir -p ${INDICO_DIR} && \
    chmod go+w ${INDICO_DIR}

VOLUME ${INDICO_DIR}

# uwsgi port
EXPOSE 8008

# uwsgi stats port
EXPOSE 5050

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["run"]
