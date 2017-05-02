# sourced by catalina.sh upon start

# read the one shipped by Atlassian first
. /srv/wiki/base/bin/setenv.sh
set -x
export JAVA_OPTS="$JAVA_OPTS -Djava.awt.headless=true -Xms4096m -Xmx8192m -XX:MaxPermSize=256m -XX:OnOutOfMemoryError=/srv/wiki/site/bin/oomkill"
