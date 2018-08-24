# sourced by catalina.sh upon start

# Don't read the one shipped by Atlassian first
#. /srv/wiki/base/bin/setenv.sh

set -x

CONFLUENCE_CONTEXT_PATH=$("${JAVA_HOME}/bin/java -jar ${CATALINA_HOME}/bin/confluence-context-path-extractor.jar ${CATALINA_HOME}")

CATALINA_OPTS="
 -XX:-PrintGCDetails
 -XX:+PrintGCTimeStamps
 -XX:-PrintTenuringDistribution
 -Xloggc:${HOME}/home/logs/gc-$(date +%F_%H-%M-%S).log
 -XX:+UseGCLogFileRotation
 -XX:NumberOfGCLogFiles=5
 -XX:GCLogFileSize=2M
 -XX:G1ReservePercent=20
 -Dsynchrony.enable.xhr.fallback=true
 -Dorg.apache.tomcat.websocket.DEFAULT_BUFFER_SIZE=32768
 -Dconfluence.context.path=${CONFLUENCE_CONTEXT_PATH}
 -XX:ReservedCodeCacheSize=256m
 -XX:+UseCodeCacheFlushing
 -Djava.awt.headless=true
 -Datlassian.plugins.enable.wait=300
 -Xms8192m -Xmx8192m -XX:+UseG1GC
 -XX:OnOutOfMemoryError=/srv/wiki/site/bin/oomkill
 ${CATALINA_OPTS}
"
