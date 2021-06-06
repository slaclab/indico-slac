
FROM httpd:2.4

LABEL edu.stanford.slac.indico.authors="salnikov@slac.stanford.edu"

RUN sed -i \
        -e 's/^Listen 80$/Listen 80\nListen 443/' \
        -e 's/^#\(LoadModule .*mod_allowmethods.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_proxy.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_proxy_uwsgi.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_rewrite.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
        /usr/local/apache2/conf/httpd.conf && \
    echo "Include conf/indico-sslredir.conf" >> /usr/local/apache2/conf/httpd.conf && \
    echo "Include conf/indico.conf" >> /usr/local/apache2/conf/httpd.conf

COPY ./apache-indico.conf /usr/local/apache2/conf/indico.conf
COPY ./apache-indico-sslredir.conf /usr/local/apache2/conf/indico-sslredir.conf

# indico.crt and indico.key should be here
VOLUME /etc/ssl/indico

EXPOSE 443
