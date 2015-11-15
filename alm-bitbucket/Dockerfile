FROM stealthstartuplabs/java-base
MAINTAINER Dave Jackson <dave.jackson@stealthstartuplabs.com>

RUN apt-get update  && apt-get install -y git && rm -rf /var/lib/apt/lists/* 

# Download and extract Bitbucket
ENV BITBUCKET_VERSION 4.1.0
RUN curl -Lks https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-${BITBUCKET_VERSION}.tar.gz \
         -o /root/bitbucket.tar.gz \
      && mkdir /opt/bitbucket \
      && tar zxf /root/bitbucket.tar.gz --strip=1 -C /opt/bitbucket \
      && rm /root/bitbucket.tar.gz \
      && sed -i -e "s/^#!\/bin\/sh/#!\/bin\/bash/" /opt/bitbucket/bin/catalina.sh \
      && mv /opt/bitbucket/conf/server.xml /opt/bitbucket/conf/server.xml.orig

# create group and users to run Bitbucket
RUN /usr/sbin/groupadd atlassian \
      && /usr/sbin/useradd -M --home-dir /opt/bitbucket --groups atlassian --shell /bin/bash bitbucket \
      && chown -R bitbucket:bitbucket /opt/bitbucket

ADD ./docker-entrypoint.sh /
VOLUME ["/opt/atlassian-home"]

ENV BITBUCKET_HOME /opt/atlassian-home/bitbucket
ENV CONTEXT_PATH bitbucket

EXPOSE 7990 7999

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]
