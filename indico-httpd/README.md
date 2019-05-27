Image for Indico web server
===========================

This image is based on a standard nginx image with simple change of a
configuration file to serve Indico data. Configuration assumes that host
name running Indico uwsgi service is `indico-worker` and location of static
Indico files in `/opt/indico/web`, this is also the volume defined in
indico-worker image. Configuration also needs SSL certificates at locations
`/etc/ssl/indico/indico.crt` and `/etc/ssl/indico/indico.key`, the image
defines `/etc/ssl/indico` volume, so that container can be started as:

    docker run --rm --detach \
        --name indico-httpd \
        --link indico-worker \
        --volumes-from indico-worker \
        --volume /some/path/ssl:/etc/ssl/indico \
        -p 443:443 \
        fermented/indico-httpd
