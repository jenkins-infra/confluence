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

  CFGXML=/srv/wiki/home/confluence.cfg.xml

  cat <<END > $CFGXML
<?xml version="1.0" encoding="UTF-8"?>
<confluence-configuration>
  <setupStep>setupdata-start</setupStep>
  <setupType>custom</setupType>
  <properties>
    <property name="admin.ui.allow.manual.backup.download">true</property>
    <property name="attachments.dir">/srv/wiki/home/attachments</property>
    <property name="confluence.webapp.context.path"></property>
    <property name="daily.backup.dir">/srv/wiki/home/backups</property>
    <property name="hibernate.c3p0.acquire_increment">1</property>
    <property name="hibernate.c3p0.idle_test_period">100</property>
    <property name="hibernate.c3p0.max_size">30</property>
    <property name="hibernate.c3p0.max_statements">0</property>
    <property name="hibernate.c3p0.min_size">0</property>
    <property name="hibernate.c3p0.timeout">30</property>
    <property name="hibernate.connection.driver_class">$DB_JDBC_DRIVER</property>
    <property name="hibernate.connection.password">$DB_PASSWORD</property>
    <property name="hibernate.connection.url">$DB_JDBC_URL</property>
    <property name="hibernate.connection.username">$DB_USER</property>
    <property name="hibernate.database.lower_non_ascii_supported">true</property>
    <property name="hibernate.dialect">com.atlassian.hibernate.dialect.MySQLDialect</property>
    <property name="lucene.index.dir">/srv/wiki/home/index</property>
    <property name="retrievalUrl">http://localhost:8081</property>
    <property name="rootPath">/srv/wiki/cache/display</property>
    <property name="userName">$DB_USER</property>
    <property name="password">$DB_PASSWORD</property>
    <property name="webwork.multipart.saveDir">/srv/wiki/home/temp</property>
    <property name="confluence.setup.server.id">B0NE-GNU6-ZHJG-41PT</property>
    <property name="confluence.license.hash">xxxx</property>
    <property name="confluence.license.message">yyyx</property>
END

  if [ -d ${CFGXML}.d ]; then
    cat ${CFGXML}.d/*.conf >> $CFGXML
  fi

  cat << END >> $CFGXML
  </properties>
</confluence-configuration>
END

#cat << END > /srv/wiki/home/confluence.cfg.xml
#<confluence-configuration>
#  <setupStep>setupdata-start</setupStep>
#  <setupType>custom</setupType>
#  <buildNumber>0</buildNumber>
#  <properties>
#    <property name="confluence.setup.server.id">B0NE-GNU6-ZHJG-41PT</property>
#    <property name="confluence.webapp.context.path"></property>
#    <property name="hibernate.connection.password">$DB_PASSWORD</property>
#    <property name="hibernate.connection.url">$DB_JDBC_URL</property>
#    <property name="hibernate.connection.username">$DB_USER</property>
#    <property name="hibernate.c3p0.acquire_increment">1</property>
#    <property name="hibernate.c3p0.idle_test_period">100</property>
#    <property name="hibernate.c3p0.max_size">30</property>
#    <property name="hibernate.c3p0.max_statements">0</property>
#    <property name="hibernate.c3p0.min_size">0</property>
#    <property name="hibernate.c3p0.timeout">30</property>
#    <property name="hibernate.connection.driver_class">com.mysql.jdbc.Driver</property>
#    <property name="hibernate.dialect">com.atlassian.hibernate.dialect.MySQLDialect</property>
#    <property name="lucene.index.dir">/srv/wiki/home/index</property>
#    <property name="confluence.license.hash">xxxx</property>
#    <property name="confluence.license.message">yyyx</property>
#  </properties>
#</confluence-configuration>
#END
fi

# replace front-end reverse proxy setting in server.xml
cat /srv/wiki/site/conf/server.xml | sed -e "s,@@PROXY_NAME@@,$PROXY_NAME," -e "s,@@PROXY_PORT@@,$PROXY_PORT," -e "s,@@PROXY_SCHEME@@,$PROXY_SCHEME," > /tmp/server.xml
cp /tmp/server.xml /srv/wiki/site/conf/server.xml

cat /srv/wiki/site/classes/atlassian-user.xml | sed -e "s,@@LDAP_PASSWORD@@,$LDAP_PASSWORD," > /srv/wiki/base/confluence/WEB-INF/classes/atlassian-user.xml

export CATALINA_BASE=/srv/wiki/site
/srv/wiki/base/bin/catalina.sh run
