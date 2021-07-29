#!/bin/sh

set -e
set -u

umask 022

USERNAME="`id -un`"
USERID="`id -u`"
TMP_DIR="/run/user/${USERID}/freeplane"
#TMP_DIR="/tmp/freeplane_${USERNAME}"

LOGFILE="${TMP_DIR}/freeplane.$$.log"

if [ ! -d "${TMP_DIR}" ]; then
    (
        umask 077
        mkdir "${TMP_DIR}"
    )
fi

/opt/app/freeplane/freeplane.sh  >"${LOGFILE}" 2>&1
