#!/bin/bash

. /app/includes.sh

RESTORE_FILE_DB=""
RESTORE_FILE_CONFIG=""
RESTORE_FILE_RSAKEY=""
RESTORE_FILE_ATTACHMENTS=""
RESTORE_FILE_SENDS=""
RESTORE_FILE_ZIP=""
RESTORE_FILE_DIR="${RESTORE_DIR}"
ZIP_PASSWORD=""

function clear_extract_dir() {
    rm -rf "${RESTORE_EXTRACT_DIR}"
}

function restore_zip() {
    color blue "restore vaultwarden backup zip file"

    local FIND_FILE_DB
    local FIND_FILE_CONFIG
    local FIND_FILE_RSAKEY
    local FIND_FILE_ATTACHMENTS
    local FIND_FILE_SENDS

    if [[ -n "${ZIP_PASSWORD}" ]]; then
        7z e -aoa -p"${ZIP_PASSWORD}" -o"${RESTORE_EXTRACT_DIR}" "${RESTORE_FILE_ZIP}"
    else
        7z e -aoa -o"${RESTORE_EXTRACT_DIR}" "${RESTORE_FILE_ZIP}"
    fi

    if [[ $? == 0 ]]; then
        color green "extract vaultwarden backup zip file successful"
    else
        color red "extract vaultwarden backup zip file failed"
        exit 1
    fi

    # get restore db file
    FIND_FILE_DB="$( basename "$(ls ${RESTORE_EXTRACT_DIR}/db.*.sqlite3 2>/dev/null)" )"
    RESTORE_FILE_DB="${FIND_FILE_DB:-}"

    # get restore config file
    FIND_FILE_CONFIG="$( basename "$(ls ${RESTORE_EXTRACT_DIR}/config.*.json 2>/dev/null)" )"
    RESTORE_FILE_CONFIG="${FIND_FILE_CONFIG:-}"

    # get restore rsakey file
    FIND_FILE_RSAKEY="$( basename "$(ls ${RESTORE_EXTRACT_DIR}/rsakey.*.tar 2>/dev/null)" )"
    RESTORE_FILE_RSAKEY="${FIND_FILE_RSAKEY:-}"

    # get restore attachments file
    FIND_FILE_ATTACHMENTS="$( basename "$(ls ${RESTORE_EXTRACT_DIR}/attachments.*.tar 2>/dev/null)" )"
    RESTORE_FILE_ATTACHMENTS="${FIND_FILE_ATTACHMENTS:-}"

    # get restore sends file
    FIND_FILE_SENDS="$( basename "$(ls ${RESTORE_EXTRACT_DIR}/sends.*.tar 2>/dev/null)" )"
    RESTORE_FILE_SENDS="${FIND_FILE_SENDS:-}"

    RESTORE_FILE_ZIP=""
    RESTORE_FILE_DIR="${RESTORE_EXTRACT_DIR}"
    restore_file
}

function restore_db() {
    color blue "restore vaultwarden sqlite database"

    cp -f "${RESTORE_FILE_DB}" "${DATA_DB}"

    if [[ $? == 0 ]]; then
        color green "restore vaultwarden sqlite database successful"
    else
        color red "restore vaultwarden sqlite database failed"
    fi
}

function restore_config() {
    color blue "restore vaultwarden config"

    cp -f "${RESTORE_FILE_CONFIG}" "${DATA_CONFIG}"

    if [[ $? == 0 ]]; then
        color green "restore vaultwarden config successful"
    else
        color red "restore vaultwarden config failed"
    fi
}

function restore_rsakey() {
    color blue "restore vaultwarden rsakey"

    mkdir -p "${DATA_RSAKEY_DIRNAME}"
    tar -x -C "${DATA_RSAKEY_DIRNAME}" -f "${RESTORE_FILE_RSAKEY}"

    if [[ $? == 0 ]]; then
        color green "restore vaultwarden rsakey successful"
    else
        color red "restore vaultwarden rsakey failed"
    fi
}

function restore_attachments() {
    color blue "restore vaultwarden attachments"

    # When customizing the attachments folder, the root directory of the tar file
    # is the directory name at the time of packing
    local RESTORE_FILE_ATTACHMENTS_DIRNAME=$(tar -tf "${RESTORE_FILE_ATTACHMENTS}" | head -n 1 | xargs basename)
    local DATA_ATTACHMENTS_EXTRACT="${DATA_ATTACHMENTS}.extract"

    rm -rf "${DATA_ATTACHMENTS}" "${DATA_ATTACHMENTS_EXTRACT}"
    mkdir -p "${DATA_ATTACHMENTS_EXTRACT}"
    tar -x -C "${DATA_ATTACHMENTS_EXTRACT}" -f "${RESTORE_FILE_ATTACHMENTS}"
    mv "${DATA_ATTACHMENTS_EXTRACT}/${RESTORE_FILE_ATTACHMENTS_DIRNAME}" "${DATA_ATTACHMENTS}"
    rm -rf "${DATA_ATTACHMENTS_EXTRACT}"

    if [[ $? == 0 ]]; then
        color green "restore vaultwarden attachments successful"
    else
        color red "restore vaultwarden attachments failed"
    fi
}

function restore_sends() {
    color blue "restore vaultwarden sends"

    # When customizing the sends folder, the root directory of the tar file
    # is the directory name at the time of packing
    local RESTORE_FILE_SENDS_DIRNAME=$(tar -tf "${RESTORE_FILE_SENDS}" | head -n 1 | xargs basename)
    local DATA_SENDS_EXTRACT="${DATA_SENDS}.extract"

    rm -rf "${DATA_SENDS}" "${DATA_SENDS_EXTRACT}"
    mkdir -p "${DATA_SENDS_EXTRACT}"
    tar -x -C "${DATA_SENDS_EXTRACT}" -f "${RESTORE_FILE_SENDS}"
    mv "${DATA_SENDS_EXTRACT}/${RESTORE_FILE_SENDS_DIRNAME}" "${DATA_SENDS}"
    rm -rf "${DATA_SENDS_EXTRACT}"

    if [[ $? == 0 ]]; then
        color green "restore vaultwarden sends successful"
    else
        color red "restore vaultwarden sends failed"
    fi
}

function check_restore_file_exist() {
    if [[ ! -f "${RESTORE_FILE_DIR}/$1" ]]; then
        color red "$2: cannot access $1: No such file"
        exit 1
    fi
}

function restore_file() {
    if [[ -n "${RESTORE_FILE_ZIP}" ]]; then
        check_restore_file_exist "${RESTORE_FILE_ZIP}" "--zip-file"

        RESTORE_FILE_ZIP="${RESTORE_FILE_DIR}/${RESTORE_FILE_ZIP}"

        clear_extract_dir
        restore_zip
        clear_extract_dir
    else
        if [[ -n "${RESTORE_FILE_DB}" ]]; then
            check_restore_file_exist "${RESTORE_FILE_DB}" "--db-file"

            RESTORE_FILE_DB="${RESTORE_FILE_DIR}/${RESTORE_FILE_DB}"
        fi

        if [[ -n "${RESTORE_FILE_CONFIG}" ]]; then
            check_restore_file_exist "${RESTORE_FILE_CONFIG}" "--config-file"

            RESTORE_FILE_CONFIG="${RESTORE_FILE_DIR}/${RESTORE_FILE_CONFIG}"
        fi

        if [[ -n "${RESTORE_FILE_RSAKEY}" ]]; then
            check_restore_file_exist "${RESTORE_FILE_RSAKEY}" "--rsakey-file"

            RESTORE_FILE_RSAKEY="${RESTORE_FILE_DIR}/${RESTORE_FILE_RSAKEY}"
        fi

        if [[ -n "${RESTORE_FILE_ATTACHMENTS}" ]]; then
            check_restore_file_exist "${RESTORE_FILE_ATTACHMENTS}" "--attachments-file"

            RESTORE_FILE_ATTACHMENTS="${RESTORE_FILE_DIR}/${RESTORE_FILE_ATTACHMENTS}"
        fi

        if [[ -n "${RESTORE_FILE_SENDS}" ]]; then
            check_restore_file_exist "${RESTORE_FILE_SENDS}" "--sends-file"

            RESTORE_FILE_SENDS="${RESTORE_FILE_DIR}/${RESTORE_FILE_SENDS}"
        fi

        if [[ -n "${RESTORE_FILE_DB}" ]]; then
            restore_db
        fi
        if [[ -n "${RESTORE_FILE_CONFIG}" ]]; then
            restore_config
        fi
        if [[ -n "${RESTORE_FILE_RSAKEY}" ]]; then
            restore_rsakey
        fi
        if [[ -n "${RESTORE_FILE_ATTACHMENTS}" ]]; then
            restore_attachments
        fi
        if [[ -n "${RESTORE_FILE_SENDS}" ]]; then
            restore_sends
        fi
    fi
}

function check_empty_input() {
    if [[ -z "${RESTORE_FILE_ZIP}${RESTORE_FILE_DB}${RESTORE_FILE_CONFIG}${RESTORE_FILE_RSAKEY}${RESTORE_FILE_ATTACHMENTS}${RESTORE_FILE_SENDS}" ]]; then
        color yellow "Empty input"
        color none ""
        color none "Find out more at https://github.com/ttionya/vaultwarden-backup#restore"
        exit 0
    fi
}

function check_data_dir_exist() {
    if [[ ! -d "${DATA_DIR}" ]]; then
        color red "vaultwarden data directory not found"
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
                RESTORE_FILE_ZIP="$(basename "$1")"
                shift
                ;;
            --db-file)
                shift
                RESTORE_FILE_DB="$(basename "$1")"
                shift
                ;;
            --config-file)
                shift
                RESTORE_FILE_CONFIG="$(basename "$1")"
                shift
                ;;
            --rsakey-file)
                shift
                RESTORE_FILE_RSAKEY="$(basename "$1")"
                shift
                ;;
            --attachments-file)
                shift
                RESTORE_FILE_ATTACHMENTS="$(basename "$1")"
                shift
                ;;
            --sends-file)
                shift
                RESTORE_FILE_SENDS="$(basename "$1")"
                shift
                ;;
            *)
                color red "Illegal input"
                exit 1
                ;;
        esac
    done

    init_env_dir
    check_empty_input
    check_data_dir_exist

    color yellow "Restore will overwrite the existing files, continue? (y/N)"
    read -p "(Default: n): " READ_RESTORE_CONTINUE
    if [[ $(echo "${READ_RESTORE_CONTINUE:-n}" | tr [a-z] [A-Z]) == "Y" ]]; then
        restore_file
    fi
}
