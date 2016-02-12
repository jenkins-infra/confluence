# sourced by catalina.sh upon start

# read the one shipped by Atlassian first
. /srv/wiki/base/bin/setenv.sh
set -x
export JAVA_OPTS="${JAVA_OPTS} -Djava.awt.headless=true -Xms512m -Xmx1024m -XX:MaxPermSize=256m -XX:+HeapDumpOnOutOfMemoryError -XX:OnOutOfMemoryError=\\\"kill -9 %p\\\""
