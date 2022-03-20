#!/bin/bash

ENV_FILE="/.env"
BACKUP_DIR="/bitwarden/backup"
RESTORE_DIR="/bitwarden/restore"
RESTORE_EXTRACT_DIR="/bitwarden/extract"

#################### Function ####################
########################################
# Print colorful message.
# Arguments:
#     color
#     message
# Outputs:
#     colorful message
########################################
function color() {
    case $1 in
        red)     echo -e "\033[31m$2\033[0m" ;;
        green)   echo -e "\033[32m$2\033[0m" ;;
        yellow)  echo -e "\033[33m$2\033[0m" ;;
        blue)    echo -e "\033[34m$2\033[0m" ;;
        none)    echo "$2" ;;
    esac
}

########################################
# Check storage system connection success.
# Arguments:
#     None
########################################
function check_rclone_connection() {
    rclone ${RCLONE_GLOBAL_FLAG} config show "${RCLONE_REMOTE_NAME}" > /dev/null 2>&1
    if [[ $? != 0 ]]; then
        color red "rclone configuration information not found"
        color blue "Please configure rclone first, check https://github.com/ttionya/vaultwarden-backup/blob/master/README.md#backup"
        exit 1
    fi

    rclone ${RCLONE_GLOBAL_FLAG} mkdir "${RCLONE_REMOTE}"
    if [[ $? != 0 ]]; then
        color red "storage system connection failure"
        exit 1
    fi
}

########################################
# Check file is exist.
# Arguments:
#     file
########################################
function check_file_exist() {
    if [[ ! -f "$1" ]]; then
        color red "cannot access $1: No such file"
        exit 1
    fi
}

########################################
# Check directory is exist.
# Arguments:
#     directory
########################################
function check_dir_exist() {
    if [[ ! -d "$1" ]]; then
        color red "cannot access $1: No such directory"
        exit 1
    fi
}

########################################
# Send mail by mailx.
# Arguments:
#     mail subject
#     mail content
# Outputs:
#     send mail result
########################################
function send_mail() {
    if [[ "${MAIL_DEBUG}" == "TRUE" ]]; then
        local MAIL_VERBOSE="-v"
    fi

    echo "$2" | mailx ${MAIL_VERBOSE} -s "$1" ${MAIL_SMTP_VARIABLES} "${MAIL_TO}"
    if [[ $? != 0 ]]; then
        color red "mail sending failed"
    else
        color blue "mail send was successfully"
    fi
}

########################################
# Send mail.
# Arguments:
#     backup successful
#     mail content
########################################
function send_mail_content() {
    if [[ "${MAIL_SMTP_ENABLE}" == "FALSE" ]]; then
        return
    fi

    # successful
    if [[ "$1" == "TRUE" && "${MAIL_WHEN_SUCCESS}" == "TRUE" ]]; then
        send_mail "vaultwarden Backup Success" "$2"
    fi

    # failed
    if [[ "$1" == "FALSE" && "${MAIL_WHEN_FAILURE}" == "TRUE" ]]; then
        send_mail "vaultwarden Backup Failed" "$2"
    fi
}

########################################
# Send health check ping.
# Arguments:
#     None
########################################
function send_ping() {
    if [[ -z "${PING_URL}" ]]; then
        return
    fi

    wget "${PING_URL}" -T 15 -t 10 -O /dev/null -q
    if [[ $? != 0 ]]; then
        color red "ping sending failed"
    else
        color blue "ping send was successfully"
    fi
}

########################################
# Export variables from .env file.
# Arguments:
#     None
# Outputs:
#     variables with prefix 'DOTENV_'
# Reference:
#     https://gist.github.com/judy2k/7656bfe3b322d669ef75364a46327836#gistcomment-3632918
########################################
function export_env_file() {
    if [[ -f "${ENV_FILE}" ]]; then
        color blue "find \"${ENV_FILE}\" file and export variables"
        set -a
        source <(cat "${ENV_FILE}" | sed -e '/^#/d;/^\s*$/d' -e 's/\(\w*\)[ \t]*=[ \t]*\(.*\)/DOTENV_\1=\2/')
        set +a
    fi
}

########################################
# Get variables from
#     environment variables,
#     secret file in environment variables,
#     secret file in .env file,
#     environment variables in .env file.
# Arguments:
#     variable name
# Outputs:
#     variable value
########################################
function get_env() {
    local VAR="$1"
    local VAR_FILE="${VAR}_FILE"
    local VAR_DOTENV="DOTENV_${VAR}"
    local VAR_DOTENV_FILE="DOTENV_${VAR_FILE}"
    local VALUE=""

    if [[ -n "${!VAR:-}" ]]; then
        VALUE="${!VAR}"
    elif [[ -n "${!VAR_FILE:-}" ]]; then
        VALUE="$(cat "${!VAR_FILE}")"
    elif [[ -n "${!VAR_DOTENV_FILE:-}" ]]; then
        VALUE="$(cat "${!VAR_DOTENV_FILE}")"
    elif [[ -n "${!VAR_DOTENV:-}" ]]; then
        VALUE="${!VAR_DOTENV}"
    fi

    export "${VAR}=${VALUE}"
}

########################################
# Initialization environment variables.
# Arguments:
#     None
# Outputs:
#     environment variables
########################################
function init_env() {
    # export
    export_env_file

    init_env_dir
    init_env_mail

    # CRON
    get_env CRON
    CRON="${CRON:-"5 * * * *"}"

    # RCLONE_REMOTE_NAME
    get_env RCLONE_REMOTE_NAME
    RCLONE_REMOTE_NAME="${RCLONE_REMOTE_NAME:-"BitwardenBackup"}"

    # RCLONE_REMOTE_DIR
    get_env RCLONE_REMOTE_DIR
    RCLONE_REMOTE_DIR="${RCLONE_REMOTE_DIR:-"/BitwardenBackup/"}"

    # RCLONE_REMOTE
    RCLONE_REMOTE=$(echo "${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_DIR}" | sed 's@\(/*\)$@@')

    # RCLONE_GLOBAL_FLAG
    get_env RCLONE_GLOBAL_FLAG
    RCLONE_GLOBAL_FLAG="${RCLONE_GLOBAL_FLAG:-""}"

    # ZIP_ENABLE
    get_env ZIP_ENABLE
    ZIP_ENABLE=$(echo "${ZIP_ENABLE}" | tr '[a-z]' '[A-Z]')
    if [[ "${ZIP_ENABLE}" == "FALSE" ]]; then
        ZIP_ENABLE="FALSE"
    else
        ZIP_ENABLE="TRUE"
    fi

    # ZIP_PASSWORD
    get_env ZIP_PASSWORD
    ZIP_PASSWORD="${ZIP_PASSWORD:-"WHEREISMYPASSWORD?"}"

    # ZIP_TYPE
    get_env ZIP_TYPE
    ZIP_TYPE=$(echo "${ZIP_TYPE}" | tr '[A-Z]' '[a-z]')
    if [[ "${ZIP_TYPE}" == "7z" ]]; then
        ZIP_TYPE="7z"
    else
        ZIP_TYPE="zip"
    fi

    # BACKUP_KEEP_DAYS
    get_env BACKUP_KEEP_DAYS
    BACKUP_KEEP_DAYS="${BACKUP_KEEP_DAYS:-"0"}"

    # BACKUP_FILE_DATE_FORMAT
    get_env BACKUP_FILE_DATE_SUFFIX
    BACKUP_FILE_DATE_FORMAT=$(echo "%Y%m%d${BACKUP_FILE_DATE_SUFFIX}" | sed 's/[^0-9a-zA-Z%_-]//g')

    # PING_URL
    get_env PING_URL
    PING_URL="${PING_URL:-""}"

    # TIMEZONE
    get_env TIMEZONE
    local TIMEZONE_MATCHED_COUNT=$(ls "/usr/share/zoneinfo/${TIMEZONE}" 2> /dev/null | wc -l)
    if [[ "${TIMEZONE_MATCHED_COUNT}" -ne 1 ]]; then
        TIMEZONE="UTC"
    fi

    color yellow "========================================"
    color yellow "DATA_DIR: ${DATA_DIR}"
    color yellow "DATA_DB: ${DATA_DB}"
    color yellow "DATA_CONFIG: ${DATA_CONFIG}"
    color yellow "DATA_RSAKEY: ${DATA_RSAKEY}"
    color yellow "DATA_ATTACHMENTS: ${DATA_ATTACHMENTS}"
    color yellow "DATA_SENDS: ${DATA_SENDS}"
    color yellow "========================================"
    color yellow "CRON: ${CRON}"
    color yellow "RCLONE_REMOTE_NAME: ${RCLONE_REMOTE_NAME}"
    color yellow "RCLONE_REMOTE_DIR: ${RCLONE_REMOTE_DIR}"
    color yellow "RCLONE_REMOTE: ${RCLONE_REMOTE}"
    color yellow "RCLONE_GLOBAL_FLAG: ${RCLONE_GLOBAL_FLAG}"
    color yellow "ZIP_ENABLE: ${ZIP_ENABLE}"
    color yellow "ZIP_PASSWORD: ${#ZIP_PASSWORD} Chars"
    color yellow "ZIP_TYPE: ${ZIP_TYPE}"
    color yellow "BACKUP_FILE_DATE_FORMAT: ${BACKUP_FILE_DATE_FORMAT}"
    color yellow "BACKUP_KEEP_DAYS: ${BACKUP_KEEP_DAYS}"
    if [[ -n "${PING_URL}" ]]; then
        color yellow "PING_URL: ${PING_URL}"
    fi
    color yellow "MAIL_SMTP_ENABLE: ${MAIL_SMTP_ENABLE}"
    if [[ "${MAIL_SMTP_ENABLE}" == "TRUE" ]]; then
        color yellow "MAIL_TO: ${MAIL_TO}"
        color yellow "MAIL_WHEN_SUCCESS: ${MAIL_WHEN_SUCCESS}"
        color yellow "MAIL_WHEN_FAILURE: ${MAIL_WHEN_FAILURE}"
    fi
    color yellow "TIMEZONE: ${TIMEZONE}"
    color yellow "========================================"
}

function init_env_dir() {
    # DATA_DIR
    get_env DATA_DIR
    DATA_DIR="${DATA_DIR:-"/bitwarden/data"}"
    check_dir_exist "${DATA_DIR}"

    # DATA_DB
    get_env DATA_DB
    DATA_DB="${DATA_DB:-"${DATA_DIR}/db.sqlite3"}"

    # DATA_CONFIG
    DATA_CONFIG="${DATA_DIR}/config.json"

    # DATA_RSAKEY
    get_env DATA_RSAKEY
    DATA_RSAKEY="${DATA_RSAKEY:-"${DATA_DIR}/rsa_key"}"
    DATA_RSAKEY_DIRNAME="$(dirname "${DATA_RSAKEY}")"
    DATA_RSAKEY_BASENAME="$(basename "${DATA_RSAKEY}")"

    # DATA_ATTACHMENTS
    get_env DATA_ATTACHMENTS
    DATA_ATTACHMENTS="$(dirname "${DATA_ATTACHMENTS:-"${DATA_DIR}/attachments"}/useless")"
    DATA_ATTACHMENTS_DIRNAME="$(dirname "${DATA_ATTACHMENTS}")"
    DATA_ATTACHMENTS_BASENAME="$(basename "${DATA_ATTACHMENTS}")"

    # DATA_SEND
    get_env DATA_SENDS
    DATA_SENDS="$(dirname "${DATA_SENDS:-"${DATA_DIR}/sends"}/useless")"
    DATA_SENDS_DIRNAME="$(dirname "${DATA_SENDS}")"
    DATA_SENDS_BASENAME="$(basename "${DATA_SENDS}")"
}

function init_env_mail() {
    # MAIL_SMTP_ENABLE
    # MAIL_TO
    get_env MAIL_SMTP_ENABLE
    get_env MAIL_TO
    MAIL_SMTP_ENABLE=$(echo "${MAIL_SMTP_ENABLE}" | tr '[a-z]' '[A-Z]')
    if [[ "${MAIL_SMTP_ENABLE}" == "TRUE" && "${MAIL_TO}" ]]; then
        MAIL_SMTP_ENABLE="TRUE"
    else
        MAIL_SMTP_ENABLE="FALSE"
    fi

    # MAIL_SMTP_VARIABLES
    get_env MAIL_SMTP_VARIABLES
    MAIL_SMTP_VARIABLES="${MAIL_SMTP_VARIABLES:-""}"

    # MAIL_WHEN_SUCCESS
    get_env MAIL_WHEN_SUCCESS
    MAIL_WHEN_SUCCESS=$(echo "${MAIL_WHEN_SUCCESS}" | tr '[a-z]' '[A-Z]')
    if [[ "${MAIL_WHEN_SUCCESS}" == "FALSE" ]]; then
        MAIL_WHEN_SUCCESS="FALSE"
    else
        MAIL_WHEN_SUCCESS="TRUE"
    fi

    # MAIL_WHEN_FAILURE
    get_env MAIL_WHEN_FAILURE
    MAIL_WHEN_FAILURE=$(echo "${MAIL_WHEN_FAILURE}" | tr '[a-z]' '[A-Z]')
    if [[ "${MAIL_WHEN_FAILURE}" == "FALSE" ]]; then
        MAIL_WHEN_FAILURE="FALSE"
    else
        MAIL_WHEN_FAILURE="TRUE"
    fi
}
