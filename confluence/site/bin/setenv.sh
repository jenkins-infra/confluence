# sourced by catalina.sh upon start

# read the one shipped by Atlassian first
. /srv/wiki/base/bin/setenv.sh

export JAVA_OPTS="-Xms512m -Xmx640m -XX:MaxPermSize=192m $JAVA_OPTS -Djava.awt.headless=true "
