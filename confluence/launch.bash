#!/bin/bash
set -o errexit

. /usr/local/share/atlassian/common.bash

sudo own-volume

if [ -n "$DATABASE_URL" ]; then
  extract_database_url "$DATABASE_URL" DB /srv/wiki/base/lib
  DB_JDBC_URL="$(xmlstarlet esc "$DB_JDBC_URL")"
  SCHEMA=''
  if [ "$DB_TYPE" != "mysql" ]; then
    SCHEMA='<schema-name>public</schema-name>'
  fi
fi

# replace front-end reverse proxy setting in server.xml
cat /srv/wiki/site/conf/server.xml | sed -e "s,@@PROXY_NAME@@,$PROXY_NAME," -e "s,@@PROXY_PORT@@,$PROXY_PORT," -e "s,@@PROXY_SCHEME@@,$PROXY_SCHEME," > /tmp/server.xml
cp /tmp/server.xml /srv/wiki/site/conf/server.xml

cat /srv/wiki/site/classes/atlassian-user.xml | sed -e "s,@@LDAP_PASSWORD@@,$LDAP_PASSWORD," > /srv/wiki/base/confluence/WEB-INF/classes/atlassian-user.xml

export CATALINA_BASE=/srv/wiki/site
/srv/wiki/base/bin/catalina.sh run
