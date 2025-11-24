#!/bin/bash
#
# ============================================================
#
#
# ============================================================
# Description---: migrate route to new service and update labels
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
ROUTE_NAME=sso-sso-old
ROUTE_NAME_ADMIN=sso-sso-admin

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
        -n | --newroute ) shift
                          ROUTE_NAME_ADMIN="$1"
                          ;;
        * )               usage
                          exit 1
    esac
    shift
done

# Step 3: Check if you are logged in to OpenShift
check_login

# Step 4: Get New Labels from admin route
NEW_LABELS=$(oc get route ${ROUTE_NAME_NEW} -n ${PRJ_NAME} -o go-template='{{range $k, $v := .metadata.labels}}{{$k}}={{$v}} {{end}}')

# Step 5: Get Old Labels from the existing route
OLD_LABELS_TO_REMOVE=$(oc get route ${ROUTE_NAME} -n ${PRJ_NAME} -o go-template='{{range $k, $v := .metadata.labels}}{{$k}}- {{end}}')

# Step 6: Remove old labels for the existing route
oc label route ${ROUTE_NAME} -n ${PRJ_NAME} ${OLD_LABELS_TO_REMOVE}

# Step 7: Add labels to the existing route
oc label route ${ROUTE_NAME} -n ${PRJ_NAME} ${NEW_LABELS}

# Step 8: Get New Labels from admin route
NEW_ANNOTATIONS=$(oc get route ${ROUTE_NAME_NEW} -n ${PRJ_NAME} -o go-template='{{range $k, $v := .metadata.annotations}}{{$k}}={{$v}} {{end}}')

# Step 9: Get old annotations to remove
OLD_ANNOTATIONS_TO_REMOVE=$(oc get route ${ROUTE_NAME} -n ${PRJ_NAME} -o go-template='{{range $k, $v := .metadata.annotations}}{{$k}}- {{end}}')

if [ -z "${OLD_ANNOTATIONS_TO_REMOVE}" ]; then
  msg "There is not annotations to remove from route ${ROUTE_NAME}"
else
  msg "There are annotations to remove from route ${ROUTE_NAME}"
  oc annotate route ${ROUTE_NAME} -n ${PRJ_NAME} ${OLD_ANNOTATIONS_TO_REMOVE} --overwrite
  msg "Annotations removed successfully."
fi

# Step 10: Add new annotations to the existing route
oc annotate route ${ROUTE_NAME} -n ${PRJ_NAME} ${NEW_ANNOTATIONS}

# Step 11: Migrate route to new service
oc patch route ${ROUTE_NAME} -n ${PRJ_NAME} --type=json -p '[{"op": "replace", "path": "/spec/to/name", "value": "rhbk"}]'

exit 0

# EOF