#!/bin/bash
#
# ============================================================
#
#
# ============================================================
# Description---:
# ============================================================
#
#
# chmod 774 *.sh
#
#
# EOH
set -euo pipefail
#set -eo pipefail # to avoid unbound variable error


MAVEN_URL=${MAVEN_URL:-""}
MAVEN_PROFILES=${MAVEN_PROFILES:-""}
MAVEN_SETTINGS=${MAVEN_SETTINGS:-""}
MAVEN_BUILD_PROFILE=""

echo "Init ${MAVEN_SETTINGS}"

if [ -n "${MAVEN_SETTINGS}" ]; then
  MAVEN_SETTINGS=$(realpath ${MAVEN_SETTINGS})
  echo "Using the settings.xml file: ${MAVEN_SETTINGS}"
  MAVEN_SETTINGS="-s ${MAVEN_SETTINGS}"
fi

if [ -n "${MAVEN_PROFILES}" ]; then
  echo "Using the profiles Maven: ${MAVEN_PROFILES}"
  MAVEN_BUILD_PROFILE="-P${MAVEN_PROFILES}"
fi

MAVEN_ARG_URL=""
if [ -n "$MAVEN_URL" ]; then
  echo "Using the custom Maven URL: ${MAVEN_URL}"
  MAVEN_ARG_URL="-Dcustom.maven.url=${MAVEN_URL}"
fi

#
MAVEN_SSL_INSECURE="-Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -Dmaven.wagon.http.ssl.ignore.validity.dates=true"
MAVEN_OPTS="-B -ntp -q -DskipTests ${MAVEN_SSL_INSECURE}" # If you have problem with SSL to add MAVEN_SSL_INSECURE
#Ex: mvn clean package -B -ntp -q -DskipTests -Dcustom.maven.url=${MAVEN_URL} -s ~/.m2/settings.xml" -Popenshift
echo "mvn clean package ${MAVEN_OPTS}  ${MAVEN_ARG_URL} ${MAVEN_SETTINGS} ${MAVEN_BUILD_PROFILE}"
mvn clean package  ${MAVEN_OPTS}  ${MAVEN_ARG_URL} ${MAVEN_SETTINGS} ${MAVEN_BUILD_PROFILE}


exit 0

# EOF