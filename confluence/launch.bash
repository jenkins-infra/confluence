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

echo JDBC=$DB_JDBC_URL

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
cp /tmp/server.xml /srv/wiki/site/conf/server.xml

cat /srv/wiki/site/classes/atlassian-user.xml | sed \
  -e "s,@@LDAP_PASSWORD@@,$LDAP_PASSWORD," \
  > /srv/wiki/base/confluence/WEB-INF/classes/atlassian-user.xml

export CATALINA_BASE=/srv/wiki/site
/srv/wiki/base/bin/catalina.sh run
