#!/bin/bash
set -o errexit

. /usr/local/share/atlassian/common.bash

sudo own-volume

if [ -n "$DATABASE_URL" ]; then
  extract_database_url "$DATABASE_URL" DB /srv/wiki/base/lib
  SCHEMA=''
  if [ "$DB_TYPE" != "mysql" ]; then
    SCHEMA='<schema-name>public</schema-name>'
  fi
fi

# replace front-end reverse proxy setting in server.xml
# as well as DataSource configuration
cat /srv/wiki/site/conf/server.xml | sed \
  -e "s,@@PROXY_NAME@@,$PROXY_NAME," \
  -e "s,@@PROXY_PORT@@,$PROXY_PORT," \
  -e "s,@@PROXY_SCHEME@@,$PROXY_SCHEME," \
  -e "s,@@DB_USER@@,$DB_USER," \
  -e "s,@@DB_PASSWORD@@,$DB_PASSWORD," \
  -e "s,@@DB_JDBC_DRIVER@@,$DB_JDBC_DRIVER," \
  | xmlstarlet ed -u "//Resource[@name='jdbc/wiki']/@url" -v "$DB_JDBC_URL" \
  > /tmp/server.xml
mv  /tmp/server.xml /srv/wiki/site/conf/server.xml

cat /srv/wiki/site/classes/atlassian-user.xml | sed \
  -e "s,@@LDAP_PASSWORD@@,$LDAP_PASSWORD," \
  > /srv/wiki/base/confluence/WEB-INF/classes/atlassian-user.xml

CFGXML=/srv/wiki/home/confluence.cfg.xml
if [ -f $CFGXML ]; then
  # if config file already exists, touch up its database config
  cat $CFGXML \
  | xmlstarlet ed -u "//property[@name='hibernate.connection.username']" -v "$DB_USER" \
  | xmlstarlet ed -u "//property[@name='hibernate.connection.password']" -v "$DB_PASSWORD" \
  | xmlstarlet ed -u "//property[@name='hibernate.connection.url']"      -v "$DB_JDBC_URL" \
  | xmlstarlet ed -d "//property[@name='hibernate.connection.datasource']" \
  >  /tmp/confluence.cfg.xml
  mv /tmp/confluence.cfg.xml $CFGXML
fi

export CATALINA_BASE=/srv/wiki/site
/srv/wiki/base/bin/catalina.sh run
