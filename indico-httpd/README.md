Image for Indico web server
===========================

This image is based on a standard apache image with simple change of a
configuration file to serve Indico data. Configuration assumes that host
name running Indico uwsgi service is `indico-worker` and location of static
Indico files in `/opt/indico/web`, this is also the volume defined in
indico-worker image. Configuration also needs SSL certificates at locations
`/etc/ssl/indico/indico.crt` and `/etc/ssl/indico/indico.key`, the image
defines `/etc/ssl/indico` volume.

Compared to Indico instructions:
- disabled XSendFile directives as standard Apache image does not include
  mod_xsendile, and we now handle X-Sendfile header in uwsgi,
- commented-out all Alias directives as they arenot used (ProxyPass / takes
  precedence)
- Added AllowMethods and TraceEnable to filter out methods that are not
  supported by Indico

The image is now using /opt/indico for logging only, we may want to reconsider
that and log to some other location to reduce dependency on volumes.
