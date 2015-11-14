FROM httpd:2.4
MAINTAINER Dave Jackson <dave.jackson@stealthstartuplabs.com>

RUN mv /usr/local/apache2/conf/httpd.conf httpd.conf.orig
ADD httpd.conf /usr/local/apache2/conf/
ADD alm-proxy.conf /usr/local/apache2/conf/extra/

