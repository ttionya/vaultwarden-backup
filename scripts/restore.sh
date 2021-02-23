#!/bin/sh

. /app/includes.sh

RESTORE_FILE_DB=""
RESTORE_FILE_CONFIG=""
RESTORE_FILE_ATTACHMENTS=""
RESTORE_FILE_ZIP=""
ZIP_PASSWORD=""

function clear_extract_dir() {
    rm -rf ${RESTORE_EXTRACT_DIR}
}

function restore_zip() {
    color blue "restore bitwarden_rs backup zip file"

    local FIND_FILE_DB
    local FIND_FILE_CONFIG
    local FIND_FILE_ATTACHMENTS

    if [[ -n "${ZIP_PASSWORD}" ]]; then
        unzip -P ${ZIP_PASSWORD} ${RESTORE_FILE_ZIP} -d ${RESTORE_EXTRACT_DIR}
    else
        unzip ${RESTORE_FILE_ZIP} -d ${RESTORE_EXTRACT_DIR}
    fi

    if [[ $? == 0 ]]; then
        color green "extract bitwarden_rs backup zip file successful"
    else
        color red "extract bitwarden_rs backup zip file failed"
        exit 1
    fi

    # get restore db file
    RESTORE_FILE_DB=""
    FIND_FILE_DB=$(basename $(ls ${RESTORE_EXTRACT_DIR}/db.*.sqlite3))
    if [[ -n "${FIND_FILE_DB}" ]]; then
        RESTORE_FILE_DB="extract/${FIND_FILE_DB}"
    fi

    # get restore config file
    RESTORE_FILE_CONFIG=""
    FIND_FILE_CONFIG=$(basename $(ls ${RESTORE_EXTRACT_DIR}/config.*.json))
    if [[ -n "${FIND_FILE_CONFIG}" ]]; then
        RESTORE_FILE_CONFIG="extract/${FIND_FILE_CONFIG}"
    fi

    # get restore attachments file
    RESTORE_FILE_ATTACHMENTS=""
    FIND_FILE_ATTACHMENTS=$(basename $(ls ${RESTORE_EXTRACT_DIR}/attachments.*.tar))
    if [[ -n "${FIND_FILE_ATTACHMENTS}" ]]; then
        RESTORE_FILE_ATTACHMENTS="extract/${FIND_FILE_ATTACHMENTS}"
    fi

    RESTORE_FILE_ZIP=""
    restore_file
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

        clear_extract_dir
        restore_zip
        clear_extract_dir
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

function check_empty_input() {
    if [[ -z "${RESTORE_FILE_ZIP}${RESTORE_FILE_DB}${RESTORE_FILE_CONFIG}${RESTORE_FILE_ATTACHMENTS}" ]]; then
        color yellow "Empty input"
        color none ""
        color none "Find out more at https://github.com/ttionya/BitwardenRS-Backup#restore"
        exit 0
    fi
}

function check_data_dir_exist() {
    if [[ ! -d "${DATA_DIR}" ]]; then
        color red "Bitwarden data directory not found"
        exit 1
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

    check_empty_input
    check_data_dir_exist

    color yellow "Restore will overwrite the existing files, continue? (y/N)"
    read -p "(Default: n): " READ_RESTORE_CONTINUE
    if [[ $(echo "${READ_RESTORE_CONTINUE:-n}" | tr [a-z] [A-Z]) == "Y" ]]; then
        restore_file
    fi
}
