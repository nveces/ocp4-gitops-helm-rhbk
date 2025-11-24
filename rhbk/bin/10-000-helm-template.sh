#!/bin/bash
#
# ============================================================
#
#
# ============================================================
# Description---:
#
#
# ============================================================
#
# chmod 774 *.sh
#
#
# EOH

set -euo pipefail
#set -uo pipefail

# Step 1: Set current DIR and default variables:
V_ADMIN_DIR=$(dirname $0)
source ${V_ADMIN_DIR}/00-functions.sh

ENVIRONMENT=lab
HELM_DIR=${V_ADMIN_DIR}/../helm
OUTPUT_DIR=${V_ADMIN_DIR}/../../target/${ENVIRONMENT}-output
VALUES_FILES=""


# Step 2 - Parser Input Parameters
while [ $# -gt 0 ]
do
    case $1 in
        -e | --env )      shift
                          ENVIRONMENT="$1"
                          ;;
        -o | --output )   shift
                          OUTPUT_DIR="$1"
                          ;;
        * )               usage
                          exit 1
    esac
    shift
done

VALUES_DIR=${V_ADMIN_DIR}/../values/${ENVIRONMENT}
VALUES_ENV_DIR=${VALUES_DIR}
msg "Using values directory: ${VALUES_ENV_DIR}"

# Step 3: Get the configuration files for values
while read valuesFile; do
    VALUES_FILES+="${valuesFile},"
done < <(find ${VALUES_ENV_DIR} -mindepth 1 -maxdepth 1 -type f )


if [ -z "${VALUES_FILES}" ]; then
    err "No values files found in ${VALUES_ENV_DIR}. Exiting."
    exit 1
fi

VALUES_FILES=${VALUES_FILES::-1}
msg "Using values files: ${VALUES_FILES}"

# Step 4: Generate Helm template
msg "helm template ${HELM_DIR} --values ${VALUES_FILES} --output-dir ${OUTPUT_DIR} --debug"
helm template ${HELM_DIR} --values ${VALUES_FILES} --output-dir ${OUTPUT_DIR} --debug


exit 0

# EOF