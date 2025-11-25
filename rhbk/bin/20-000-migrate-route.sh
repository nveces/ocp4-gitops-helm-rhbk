#!/bin/bash
#
# ============================================================
# Red Hat Consulting EMEA, 2025
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
ROUTE_NAME=sso
ROUTE_NAME_ADMIN=rhbk-sso-admin

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
NEW_LABELS=$(oc get route ${ROUTE_NAME_ADMIN} -n ${PRJ_NAME} -o go-template='{{range $k, $v := .metadata.labels}}{{$k}}={{$v}} {{end}}')

# Step 5: Get Old Labels from the existing route
OLD_LABELS_TO_REMOVE=$(oc get route ${ROUTE_NAME} -n ${PRJ_NAME} -o go-template='{{range $k, $v := .metadata.labels}}{{$k}}- {{end}}')

# Step 6: Remove old labels for the existing route
oc label route ${ROUTE_NAME} -n ${PRJ_NAME} ${OLD_LABELS_TO_REMOVE}

# Step 7: Add labels to the existing route
oc label route ${ROUTE_NAME} -n ${PRJ_NAME} ${NEW_LABELS}

# Step 8: Get New Labels from admin route
ANNOTATE_FILE_PATH="${V_ADMIN_DIR}/annotations.tmp"
#oc get route ${ROUTE_NAME_ADMIN} -n ${PRJ_NAME} -o go-template='{{range $k, $v := .metadata.annotations}}{{if ne $k "kubectl.kubernetes.io/last-applied-configuration"}}{{printf "%s=%q\n" $k $v}}{{end}}{{end}}' > ${ANNOTATE_FILE_PATH}
oc get route ${ROUTE_NAME_ADMIN} -n ${PRJ_NAME} -o go-template='{{range $k, $v := .metadata.annotations}}{{if ne $k "kubectl.kubernetes.io/last-applied-configuration"}}{{printf "%s=%s\n" $k $v}}{{end}}{{end}}' > ${ANNOTATE_FILE_PATH}

#NEW_ANNOTATIONS=$(oc get route ${ROUTE_NAME_ADMIN} -n ${PRJ_NAME} -o go-template='{{range $k, $v := .metadata.annotations}}{{if ne $k "kubectl.kubernetes.io/last-applied-configuration"}}{{printf "%s=%s " $k $v}} {{end}}{{end}}' )
#NEW_ANNOTATIONS=$(oc get route ${ROUTE_NAME_ADMIN} -n ${PRJ_NAME} -o go-template='{{range $k, $v := .metadata.annotations}}{{if ne $k "kubectl.kubernetes.io/last-applied-configuration"}}{{printf "%s=%q\n" $k $v}}{{end}}{{end}}' )

# Step 9: Get old annotations to remove
OLD_ANNOTATIONS_TO_REMOVE=$(oc get route ${ROUTE_NAME} -n ${PRJ_NAME} -o go-template='{{range $k, $v := .metadata.annotations}}{{$k}}- {{end}}')
msg "Annotations: ${OLD_ANNOTATIONS_TO_REMOVE}"

if [ -z "${OLD_ANNOTATIONS_TO_REMOVE}" ]; then
  msg "There is not annotations to remove from route ${ROUTE_NAME}"
else
  msg "There are annotations to remove from route '${ROUTE_NAME}' '${OLD_ANNOTATIONS_TO_REMOVE}'"
  oc annotate route ${ROUTE_NAME} -n ${PRJ_NAME} ${OLD_ANNOTATIONS_TO_REMOVE} --overwrite
  msg "Annotations removed successfully."
fi

# Step 10: Add new annotations to the existing route
# Read all lines from the ANNOTATE_FILE_PATH and apply them
while IFS= read -r LINE; do
    # If the line exists, apply the annotation
    if [[ ! -z "${LINE}" ]]; then
        msg "Applying the anntate: ${LINE}"
        oc annotate route ${ROUTE_NAME} -n ${PRJ_NAME} "${LINE}" --overwrite
    fi
done < "${ANNOTATE_FILE_PATH}"

# Step 11: Remove the temporary file
rm -f "${ANNOTATE_FILE_PATH}"

# Step 12: Migrate route to new service
oc patch route ${ROUTE_NAME} -n ${PRJ_NAME} --type=json -p '[{"op": "replace", "path": "/spec/to/name", "value": "rhbk"}]'

exit 0

#
# EOF