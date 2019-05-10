#
# This image will be used as a base for Indico worker image.
#

# Based on Debian stable
FROM debian:stretch

MAINTAINER salnikov@slac.stanford.edu

RUN apt-get update && \
    apt-get install --assume-yes --no-install-recommends texlive-xetex && \
    apt-get autoclean && \
    apt-get clean
