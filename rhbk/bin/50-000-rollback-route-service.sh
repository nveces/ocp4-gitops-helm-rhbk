#!/bin/bash
#
# ============================================================
#
#
# ============================================================
# Description---: ROLLBACK migrate route to new service and update labels
# ============================================================
# migrate-route
# reconfigure-route
# traffic-switch
# route-swap
# route-update
# route-cleanup
#
# ============================================================
#
# chmod 774 *.sh
#
#
# EOH

#set -euo pipefail
set -uo pipefail

# Step 1: Set current DIR and default variables:
V_ADMIN_DIR=$(dirname $0)
source ${V_ADMIN_DIR}/00-functions.sh

PRJ_NAME=sso-lab
ROUTE_NAME=sso

# Step 2 - Parser Input Parameters
while [ $# -gt 0 ]
do
    case $1 in
        -p | --prj )      shift
                          PRJ_NAME="$1"
                          ;;
        -r | --route )    shift
                          ROUTE_NAME="$1"
                          ;;
        * )               usage
                          exit 1
    esac
    shift
done

# Step 3: Check if you are logged in to OpenShift
check_login

# Step 4: Rollback route to previous service: "sso"
oc patch route ${ROUTE_NAME} -n ${PRJ_NAME} --type=json -p '[{"op": "replace", "path": "/spec/to/name", "value": "sso"}]'

# Step 5: Rollback route to previous service: "sso", remove spec.port
oc patch route ${ROUTE_NAME} -n ${PRJ_NAME} --type=json -p='[{"op": "remove", "path": "/spec/port"}]'

exit 0

#
# EOF
