#!/bin/sh

set -e
set -u

FREEPLANE_CHANGELOG_URL="https://www.freeplane.org/info/history/history_en.txt"
FREEPLANE_DOWNLOAD_URL_TEMPLATE="https://sourceforge.net/projects/freeplane/files/freeplane%20stable/freeplane_bin-{version}.zip/download"
FREEPLANE_PACKAGE_TEMPLATE="freeplane_bin-{version}.zip"

VERSIONS_DIR="/opt/versions"
FREEPLANE_VERSIONS_DIR="${VERSIONS_DIR}/freeplane"

APP_DIR="/opt/app"
FREEPLANE_APP_LINK="${APP_DIR}/freeplane"

DOWNLOAD_DIR="${HOME}/Downloads"

GetLatestVersion() {
    local changelog_url="$1"
    curl --silent "${changelog_url}" \
        |tr -d '\r' \
        |egrep '^[ 	]*[0-9]+\.[0-9]+\.[0-9]+[ 	]*$' \
        |head -n 1 \
        |tr -d '[:space:]'
}

DownloadVersion() {
    local url_template="$1"
    local version="$2"
    local url="`echo \"${url_template}\" |sed -e 's/{version}/'${version}'/g'`"
    (
        set -x
        wget \
            --no-verbose \
            --show-progress \
            --content-disposition \
            --backups=1 \
            -P "${DOWNLOAD_DIR}" \
            "${url}"
        #curl --progress-bar --output-dir "${DOWNLOAD_DIR}" -O -J -R "${url}"
    )
}

GetDownloadPath() {
    local package_template="$1"
    local version="$2"
    local filename="`echo \"${package_template}\" |sed -e 's/{version}/'${version}'/g'`"
    echo "${DOWNLOAD_DIR}/${filename}"
}

LATEST_VERSION="`GetLatestVersion \"${FREEPLANE_CHANGELOG_URL}\"`"

DownloadVersion "${FREEPLANE_DOWNLOAD_URL_TEMPLATE}" "${LATEST_VERSION}"

PACKAGE="`GetDownloadPath \"${FREEPLANE_PACKAGE_TEMPLATE}\" \"${LATEST_VERSION}\"`"

if [ ! -d "${VERSIONS_DIR}" ]; then
    (
        set -x
        sudo mkdir "${VERSIONS_DIR}"
    )
fi
if [ ! -d "${FREEPLANE_VERSIONS_DIR}" ]; then
    (
        set -x
        sudo mkdir "${FREEPLANE_VERSIONS_DIR}"
        sudo chown "`id -un`" "${FREEPLANE_VERSIONS_DIR}"
    )
fi
if [ ! -d "${APP_DIR}" ]; then
    (
        set -x
        sudo mkdir "${APP_DIR}"
    )
fi

FREEPLANE_DIRNAME="freeplane-${LATEST_VERSION}"
FREEPLANE_UNPACK_DIR="${FREEPLANE_VERSIONS_DIR}/tmp"

(
    set -x
    rm -rf "${FREEPLANE_UNPACK_DIR}"
    mkdir "${FREEPLANE_UNPACK_DIR}"
    unzip "${PACKAGE}" -d "${FREEPLANE_UNPACK_DIR}"
    rm -rf "${FREEPLANE_VERSIONS_DIR}/${FREEPLANE_DIRNAME}"
    mv "${FREEPLANE_UNPACK_DIR}/${FREEPLANE_DIRNAME}" "${FREEPLANE_VERSIONS_DIR}/"
    ln -snf "${FREEPLANE_DIRNAME}" "${FREEPLANE_VERSIONS_DIR}/Current"
)

LEFTOVERS="`ls -1A \"${FREEPLANE_VERSIONS_DIR}/tmp\"`"
if [ -n "${LEFTOVERS}" ]; then
    echo "$0: Yikes! Leftover contents in '${FREEPLANE_UNPACK_DIR}':"
    echo "${LEFTOVERS}"
    exit 1
else
    (
        set -x
        rmdir "${FREEPLANE_UNPACK_DIR}"
    )
fi

if [ ! -e "${FREEPLANE_APP_LINK}" ]; then
    LINK_TARGET="`echo \"${FREEPLANE_VERSIONS_DIR}/Current\" |sed -e 's|^/opt/|../|'`"
    (
        set -x
        sudo ln -snf "${LINK_TARGET}" "${FREEPLANE_APP_LINK}"
    )
fi

(
    set -x
    cp -p freeplane-wrapper.sh "${FREEPLANE_VERSIONS_DIR}/"
)
