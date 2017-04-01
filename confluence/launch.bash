#!/bin/bash
set -o errexit

# install cron
crontab ~/site/cron.conf
sudo cron -f &

. /usr/local/share/atlassian/common.bash

sudo own-volume

if [ -n "$DATABASE_URL" ]; then
  extract_database_url "$DATABASE_URL" DB ~/base/lib
  SCHEMA=''
  if [ "$DB_TYPE" != "mysql" ]; then
    SCHEMA='<schema-name>public</schema-name>'
  fi
fi

# replace front-end reverse proxy setting in server.xml
# as well as DataSource configuration
cat ~/site/conf/server.xml | sed \
  -e "s,@@PROXY_NAME@@,$PROXY_NAME," \
  -e "s,@@PROXY_PORT@@,$PROXY_PORT," \
  -e "s,@@PROXY_SCHEME@@,$PROXY_SCHEME," \
  -e "s,@@DB_USER@@,$DB_USER," \
  -e "s,@@DB_PASSWORD@@,$DB_PASSWORD," \
  -e "s,@@DB_JDBC_DRIVER@@,$DB_JDBC_DRIVER," \
  -e "s,@@LDAP_HOST@@,$LDAP_HOST," \
  | xmlstarlet ed -u "//Resource[@name='jdbc/wiki']/@url" -v "$DB_JDBC_URL" \
  > /tmp/server.xml
mv  /tmp/server.xml ~/site/conf/server.xml

cat ~/site/classes/atlassian-user.xml | sed \
  -e "s,@@LDAP_PASSWORD@@,$LDAP_PASSWORD," \
  -e "s,@@LDAP_HOST@@,$LDAP_HOST," \
  > ~/base/confluence/WEB-INF/classes/atlassian-user.xml

# adds/updates a property to confluence.cfg.xml
# by first deleting and inserting, it ensures that it works correctly even if the file didn't contain the entry
# to begin with
function add-property {
  n="$1"
  v="$2"
  CFGXML=~/home/confluence.cfg.xml
  cat $CFGXML \
  | xmlstarlet ed -d "//property[@name='$n']" \
  | xmlstarlet ed -s "/confluence-configuration/properties" -t elem -n prop -v "$v" \
  | xmlstarlet ed -s "//prop" -t attr -n name -v "$n" \
  | xmlstarlet ed -r "//prop" -v "property" \
  >  /tmp/confluence.cfg.xml
  mv /tmp/confluence.cfg.xml $CFGXML
}

echo DB=$DB_JDBC_URL

CFGXML=~/home/confluence.cfg.xml
if [ -f $CFGXML ]; then
  # if config file already exists, touch up its database config
  add-property hibernate.connection.username "$DB_USER"
  add-property hibernate.connection.password "$DB_PASSWORD"
  add-property hibernate.connection.url "$(xmlstarlet esc "$DB_JDBC_URL")"
  add-property hibernate.connection.isolation "2"
  cat $CFGXML \
  | xmlstarlet ed -d "//property[@name='hibernate.connection.datasource']" \
  >  /tmp/confluence.cfg.xml
  mv /tmp/confluence.cfg.xml $CFGXML
fi

# somehow Confluence doesn't seem to create these directories on its own
mkdir -p ~/site/{temp,webapps,work}

export CATALINA_BASE=~/site
~/base/bin/catalina.sh run
