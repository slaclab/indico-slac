#!/bin/bash

#
# Pull latest tag of image from Docker Hub and add a tag to it
#

images="indico-db indico-httpd indico-latex indico-worker indico-db-backup"
tag="stable"
account="fermented"

usage() {

    cat <<USAGE

Pull the latest tag of image from DockerHub, tag it with some other tag, and
push new tag to DockerHub.

Usage: $0 [-h] [-t tag] [-a account] [image ...]

Parametes:

    image
        One or more image name, if no image is specified then all images
        are tagged: $images

Options

    -h
        Print help message and exit.

    -t tag
        Name of the new tag, default is "$tag"

    -a account
        DockerHub account name, default is "$account"

USAGE
}

while getopts ht:a: arg; do
    case "$arg" in
        h)
            usage
            exit
            ;;
        t)
            tag="${OPTARG}"
            ;;
        a)
            account="${OPTARG}"
            ;;
        ?)
            usage 1>&2
            exit 1
            ;;
    esac
done

shift $(( OPTIND - 1 ))
if [ -n "$@" ]; then
    images="$@"
fi

images="indico-latex indico-db indico-httpd indico-worker indico-db-backup"

for img in $images; do
    docker pull $account/$img:latest
    docker tag $account/$img:latest $account/$img:$tag
    docker push $account/$img:$tag
done
