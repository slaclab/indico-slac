
FROM nginx:latest

LABEL edu.stanford.slac.indico.authors="salnikov@slac.stanford.edu"

# nginx config file
COPY ./nginx-indico.conf /etc/nginx/conf.d/indico.conf

# indico.crt and indico.key should be here
VOLUME /etc/ssl/indico

EXPOSE 443
