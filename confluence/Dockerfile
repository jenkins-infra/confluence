# Basics
#
FROM durdn/atlassian-base
MAINTAINER Jenkins Infra team <infra@lists.jenkins-ci.org>


#
# When using a different version of JIRA, also be sure to tweak server.xml.
# To do a proper merge,
#   1. switch to the 'import' branch
#   2. overwrite jira/server.xml by the prestine master from JIRA distribution
#   3. commit the change to the 'import' branch
#   4. switch to the 'master' branch and merge the 'import' branch, while resolving the conflict if any.
#
ENV CONFLUENCE_VERSION 3.4.7

# Install Java. According to https://confluence.atlassian.com/display/JIRA050/Supported+Platforms
# JIRA 5.0.6 only runs on Java6 and not Java7
RUN \
  echo oracle-java6-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java6-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk6-installer

RUN /usr/sbin/useradd --create-home --home-dir /srv/wiki --groups atlassian --shell /bin/bash wiki
RUN mkdir -p /srv/wiki/base /srv/wiki/site /srv/wiki/home
# see https://www.atlassian.com/software/confluence/download-archives for options
RUN curl -Lks https://www.atlassian.com/software/confluence/downloads/binary/confluence-${CONFLUENCE_VERSION}-std.tar.gz -o /root/confluence.tar.gz; tar zxf /root/confluence.tar.gz --strip=1 -C /srv/wiki/base; rm /root/confluence.tar.gz
RUN echo "confluence.home = /srv/wiki/home" > /srv/wiki/base/confluence/WEB-INF/classes/confluence-init.properties

ADD launch.bash /launch
ADD site /srv/wiki/site

RUN chown -R wiki:wiki /srv/wiki


# The compartmentalized URL that JIRA is going to be referenced as.
ENV PROXY_SCHEME https
ENV PROXY_NAME wiki.jenkins-ci.org
ENV PROXY_PORT 443

# Password to LDAP server.
ENV LDAP_PASSWORD password

WORKDIR /srv/wiki
VOLUME ["/srv/wiki/home"]
EXPOSE 8080
USER wiki
CMD ["/launch"]
