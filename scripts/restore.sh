#!/bin/sh

. /app/includes.sh

RESTORE_FILE_DB=""
RESTORE_FILE_CONFIG=""
RESTORE_FILE_ATTACHMENTS=""
RESTORE_FILE_ZIP=""
ZIP_PASSWORD=""

function restore_zip() {
    color blue "restore bitwarden_rs backup zip file"
}

function restore_db() {
    color blue "restore bitwarden_rs sqlite database"

    cp -f ${RESTORE_FILE_DB} ${DATA_DB}

    if [[ $? == 0 ]]; then
        color green "restore bitwarden_rs sqlite database successful"
    else
        color red "restore bitwarden_rs sqlite database failed"
    fi
}

function restore_config() {
    color blue "restore bitwarden_rs config"

    cp -f ${RESTORE_FILE_CONFIG} ${DATA_CONFIG}

    if [[ $? == 0 ]]; then
        color green "restore bitwarden_rs config successful"
    else
        color red "restore bitwarden_rs config failed"
    fi
}

function restore_attachments() {
    color blue "restore bitwarden_rs attachments"

    rm -rf ${DATA_ATTACHMENTS}
    tar -x -C ${DATA_DIR} -f ${RESTORE_FILE_ATTACHMENTS}

    if [[ $? == 0 ]]; then
        color green "restore bitwarden_rs attachments successful"
    else
        color red "restore bitwarden_rs attachments failed"
    fi
}

function check_restore_file_exist() {
    if [[ ! -f "${RESTORE_DIR}/$1" ]]; then
        color red "$2: cannot access $1: No such file"
        exit 1
    fi
}

function restore_file() {
    if [[ -n "${RESTORE_FILE_ZIP}" ]]; then
        check_restore_file_exist ${RESTORE_FILE_ZIP} "--zip-file"

        RESTORE_FILE_ZIP="${RESTORE_DIR}/${RESTORE_FILE_ZIP}"

        restore_zip
    else
        if [[ -n "${RESTORE_FILE_DB}" ]]; then
            check_restore_file_exist ${RESTORE_FILE_DB} "--db-file"

            RESTORE_FILE_DB="${RESTORE_DIR}/${RESTORE_FILE_DB}"
        fi

        if [[ -n "${RESTORE_FILE_CONFIG}" ]]; then
            check_restore_file_exist ${RESTORE_FILE_CONFIG} "--config-file"

            RESTORE_FILE_CONFIG="${RESTORE_DIR}/${RESTORE_FILE_CONFIG}"
        fi

        if [[ -n "${RESTORE_FILE_ATTACHMENTS}" ]]; then
            check_restore_file_exist ${RESTORE_FILE_ATTACHMENTS} "--attachments-file"

            RESTORE_FILE_ATTACHMENTS="${RESTORE_DIR}/${RESTORE_FILE_ATTACHMENTS}"
        fi

        if [[ -n "${RESTORE_FILE_DB}" ]]; then
            restore_db
        fi
        if [[ -n "${RESTORE_FILE_CONFIG}" ]]; then
            restore_config
        fi
        if [[ -n "${RESTORE_FILE_ATTACHMENTS}" ]]; then
            restore_attachments
        fi
    fi
}

function restore() {
    local READ_RESTORE_CONTINUE

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--password)
                shift
                ZIP_PASSWORD="$1"
                shift
                ;;
            --zip-file)
                shift
                RESTORE_FILE_ZIP=$(basename "$1")
                shift
                ;;
            --db-file)
                shift
                RESTORE_FILE_DB=$(basename "$1")
                shift
                ;;
            --config-file)
                shift
                RESTORE_FILE_CONFIG=$(basename "$1")
                shift
                ;;
            --attachments-file)
                shift
                RESTORE_FILE_ATTACHMENTS=$(basename "$1")
                shift
                ;;
            *)
                color red "Illegal input"
                exit 1
                ;;
        esac
    done

    mkdir -p ${DATA_DIR}

    color yellow "Restore will overwrite the existing files, continue? (y/N)"
    read -p "(Default: n): " READ_RESTORE_CONTINUE
    if [[ $(echo "${READ_RESTORE_CONTINUE:-n}" | tr [a-z] [A-Z]) == "Y" ]]; then
        restore_file
    fi
}
