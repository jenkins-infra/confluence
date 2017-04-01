#!/bin/bash
set -o errexit


urldecode() {
    local data=${1//+/ }
    printf '%b' "${data//%/\x}"
}

parse_url() {
  local prefix=DATABASE
  [ -n "$2" ] && prefix=$2
  # extract the protocol
  local proto="`echo $1 | grep '://' | sed -e's,^\(.*://\).*,\1,g'`"
  local scheme="`echo $proto | sed -e 's,^\(.*\)://,\1,g'`"
  # remove the protocol
  local url=`echo $1 | sed -e s,$proto,,g`

  # extract the user and password (if any)
  local userpass="`echo $url | grep @ | cut -d@ -f1`"
  local pass=`echo $userpass | grep : | cut -d: -f2`
  if [ -n "$pass" ]; then
    local user=`echo $userpass | grep : | cut -d: -f1`
  else
    local user=$userpass
  fi

  # extract the host -- updated
  local hostport=`echo $url | sed -e s,$userpass@,,g | cut -d/ -f1`
  local port=`echo $hostport | grep : | cut -d: -f2`
  if [ -n "$port" ]; then
    local host=`echo $hostport | grep : | cut -d: -f1`
  else
    local host=$hostport
  fi

  # extract the path (if any)
  local full_path="`echo $url | grep / | cut -d/ -f2-`"
  local path="`echo $full_path | cut -d? -f1`"
  local query="`echo $full_path | grep ? | cut -d? -f2`"
  local -i rc=0
  
  [ -n "$proto" ] && eval "export ${prefix}_SCHEME=\"$scheme\"" || rc=$?
  [ -n "$user" ] && eval "export ${prefix}_USER=\"`urldecode $user`\"" || rc=$?
  [ -n "$pass" ] && eval "export ${prefix}_PASSWORD=\"`urldecode $pass`\"" || rc=$?
  [ -n "$host" ] && eval "export ${prefix}_HOST=\"`urldecode $host`\"" || rc=$?
  [ -n "$port" ] && eval "export ${prefix}_PORT=\"`urldecode $port`\"" || rc=$?
  [ -n "$path" ] && eval "export ${prefix}_NAME=\"`urldecode $path`\"" || rc=$?
  [ -n "$query" ] && eval "export ${prefix}_QUERY=\"$query\"" || rc=$?
}

download_mysql_driver() {
  local driver="mysql-connector-java-5.1.40"
  if [ ! -f "$1/$driver-bin.jar" ]; then
    echo "Downloading MySQL JDBC Driver..."
    curl -L http://dev.mysql.com/get/Downloads/Connector-J/$driver.tar.gz | tar zxv -C /tmp
    cp /tmp/$driver/$driver-bin.jar $1/$driver-bin.jar
  fi
}

read_var() {
  eval "echo \$$1_$2"
}

extract_database_url() {
  local url="$1"
  local prefix="$2"
  local mysql_install="$3"

  eval "unset ${prefix}_PORT"
  parse_url "$url" $prefix
  case "$(read_var $prefix SCHEME)" in
    postgres|postgresql)
      if [ -z "$(read_var $prefix PORT)" ]; then
        eval "${prefix}_PORT=5432"
      fi
      local host_port_name="$(read_var $prefix HOST):$(read_var $prefix PORT)/$(read_var $prefix NAME)"
      local jdbc_driver="org.postgresql.Driver"
      local jdbc_url="jdbc:postgresql://$host_port_name"
      local hibernate_dialect="org.hibernate.dialect.PostgreSQLDialect"
      local database_type="postgres72"
      ;;
    mysql|mysql2)
      download_mysql_driver "$mysql_install"
      if [ -z "$(read_var $prefix PORT)" ]; then
        eval "${prefix}_PORT=3306"
      fi
      local host_port_name="$(read_var $prefix HOST):$(read_var $prefix PORT)/$(read_var $prefix NAME)"
      local jdbc_driver="com.mysql.jdbc.Driver"
      local jdbc_url="jdbc:mysql://$host_port_name?autoReconnect=true&characterEncoding=utf8&useUnicode=true&sessionVariables=storage_engine%3DInnoDB"
      local hibernate_dialect="org.hibernate.dialect.MySQLDialect"
      local database_type="mysql"
      ;;
    *)
      echo "Unsupported database url scheme: $(read_var $prefix SCHEME)"
      exit 1
      ;;
  esac

  eval "${prefix}_JDBC_DRIVER=\"$jdbc_driver\""
  eval "${prefix}_JDBC_URL=\"$jdbc_url\""
  eval "${prefix}_DIALECT=\"$hibernate_dialect\""
  eval "${prefix}_TYPE=\"$database_type\""
}

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
