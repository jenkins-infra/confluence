# Basics
#
FROM openjdk:8-jre
MAINTAINER Jenkins Infra team <infra@lists.jenkins-ci.org>

ENV CONFLUENCE_VERSION 5.10.8
ENV MYSQL_DRIVER mysql-connector-java-5.1.42

# The compartmentalized URL that JIRA is going to be referenced as.
ENV PROXY_SCHEME https
ENV PROXY_NAME wiki.jenkins.io
ENV PROXY_PORT 443

# Password to LDAP server.
ENV LDAP_PASSWORD password
ENV LDAP_HOST ldap.jenkins.io

RUN apt-get -q update && apt-get install -qy cron xmlstarlet curl

RUN /usr/sbin/groupadd atlassian ; /usr/sbin/groupadd --gid 2000 wiki; /usr/sbin/useradd --create-home --home-dir /srv/wiki --groups atlassian --uid 2000 --gid wiki --shell /bin/bash wiki

RUN mkdir -p /srv/wiki/base /srv/wiki/site /srv/wiki/home

# see https://www.atlassian.com/software/confluence/download-archives for options
RUN curl -Lks https://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz -o /root/confluence.tar.gz; tar zxf /root/confluence.tar.gz --strip=1 -C /srv/wiki/base; rm /root/confluence.tar.gz

RUN echo "confluence.home = /srv/wiki/home" > /srv/wiki/base/confluence/WEB-INF/classes/confluence-init.properties

# Download and place MySQL driver
RUN curl -L http://dev.mysql.com/get/Downloads/Connector-J/${MYSQL_DRIVER}.tar.gz | tar zxv -C /tmp; \
    cp /tmp/${MYSQL_DRIVER}/${MYSQL_DRIVER}-bin.jar /srv/wiki/base/lib/${MYSQL_DRIVER}-bin.jar; \
    rm -rf /tmp/${MYSQL_DRIVER}

# Allow the user to start cron
RUN echo "wiki  ALL=(ALL) NOPASSWD: /usr/sbin/cron" >> /etc/sudoers


ADD launch.bash /launch
ADD site /srv/wiki/site

RUN chown -R wiki:wiki /srv/wiki

WORKDIR /srv/wiki
VOLUME ["/srv/wiki/home"]
EXPOSE 8080
# Needed for collaborative editing
EXPOSE 8090
USER wiki
CMD ["/launch"]
