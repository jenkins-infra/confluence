# sourced by catalina.sh upon start

# Don't read the one shipped by Atlassian first
#. /srv/wiki/base/bin/setenv.sh

set -x

CATALINA_OPTS="
 -XX:-PrintGCDetails
 -XX:+PrintGCTimeStamps
 -XX:-PrintTenuringDistribution
 -Xloggc:${HOME}/home/logs/gc-$(date +%F_%H-%M-%S).log
 -XX:+UseGCLogFileRotation
 -XX:NumberOfGCLogFiles=5
 -XX:GCLogFileSize=2M
 -Djava.awt.headless=true
 -Datlassian.plugins.enable.wait=300
 -Xms4096m -Xmx8192m -XX:+UseG1GC
 -XX:OnOutOfMemoryError=/srv/wiki/site/bin/oomkill
 ${CATALINA_OPTS}
"
