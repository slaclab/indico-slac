#!/bin/bash

#
# Pull latest tag of image from Docker Hub and add a tag to it
#

tag={$1:-stable}

account=fermented
images="indico-latex indico-db indico-httpd indico-worker indico-db-backup"

for img in $images; do
    docker pull $account/$img:latest
    docker tag $account/$img:latest $account/$img:$tag
    docker push $account/$img:$tag
done
