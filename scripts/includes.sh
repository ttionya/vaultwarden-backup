#!/bin/bash

ENV_FILE="/.env"
CRON_CONFIG_FILE="${HOME}/crontabs"
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
#     success strategy (all / any)
########################################
function check_rclone_connection() {
    # check if the configuration exists
    rclone ${RCLONE_GLOBAL_FLAG} config show "${RCLONE_REMOTE_NAME}" > /dev/null 2>&1
    if [[ $? != 0 ]]; then
        color red "rclone configuration information not found"
        color blue "Please configure rclone first, check https://github.com/ttionya/vaultwarden-backup/blob/master/README.md#backup"
        exit 1
    fi

    # check connection
    local ERROR_COUNT=0

    for RCLONE_REMOTE_X in "${RCLONE_REMOTE_LIST[@]}"
    do
        rclone ${RCLONE_GLOBAL_FLAG} lsd "${RCLONE_REMOTE_X}" > /dev/null
        if [[ $? != 0 ]]; then
            color red "storage system connection may not be initialized, try initializing $(color yellow "[${RCLONE_REMOTE_X}]")"

            rclone ${RCLONE_GLOBAL_FLAG} mkdir "${RCLONE_REMOTE_X}"
            if [[ $? != 0 ]]; then
                color red "storage system connection failure $(color yellow "[${RCLONE_REMOTE_X}]")"

                ((ERROR_COUNT++))
            fi
        fi
    done

    if [[ "${ERROR_COUNT}" -gt 0 ]]; then
        if [[ "$1" == "all" ]]; then
            color red "storage system connection failure exists"
            exit 1
        elif [[ "$1" == "any" ]]; then
            if [[ "${ERROR_COUNT}" -eq "${#RCLONE_REMOTE_LIST[@]}" ]]; then
                color red "all storage system connections failed"
                exit 1
            else
                color yellow "some storage system connections failed, but the backup will continue"
            fi
        fi
    fi
}

########################################
# Check if the file exists.
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
# Check if the directory exists.
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
# Send mail by s-nail.
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

    local THREAD_HEADERS=""
    if [[ -n "${MAIL_THREAD_ID}" ]]; then
        THREAD_HEADERS+=" -s 'Message-ID: ${MAIL_THREAD_ID}'"
        THREAD_HEADERS+=" -s 'In-Reply-To: ${MAIL_THREAD_ID}'"
        THREAD_HEADERS+=" -s 'References: ${MAIL_THREAD_ID}'"
    fi

    echo "$2" | eval "mail ${MAIL_VERBOSE} -s \"$1\" ${MAIL_SMTP_VARIABLES} ${THREAD_HEADERS} \"${MAIL_TO}\""
    # echo "$2" | eval "mail ${MAIL_VERBOSE} -s \"$1\" ${MAIL_SMTP_VARIABLES} \"${MAIL_TO}\""
    if [[ $? != 0 ]]; then
        color red "mail sending has failed"
    else
        color blue "mail has been sent successfully"
    fi
}

########################################
# Send health check or notification ping.
# Arguments:
#     ping status (completion / start / success / failure)
#     ping subject
#     ping content
# Outputs:
#     send ping result
########################################
function send_ping() {
    local CURL_URL=""
    local CURL_OPTIONS=""

    case "$1" in
        completion) CURL_URL="${PING_URL}" CURL_OPTIONS="${PING_URL_CURL_OPTIONS}" ;;
        start)      CURL_URL="${PING_URL_WHEN_START}" CURL_OPTIONS="${PING_URL_WHEN_START_CURL_OPTIONS}" ;;
        success)    CURL_URL="${PING_URL_WHEN_SUCCESS}" CURL_OPTIONS="${PING_URL_WHEN_SUCCESS_CURL_OPTIONS}" ;;
        failure)    CURL_URL="${PING_URL_WHEN_FAILURE}" CURL_OPTIONS="${PING_URL_WHEN_FAILURE_CURL_OPTIONS}" ;;
        *)          color red "illegal identifier, only supports completion, start, success, failure" ;;
    esac

    if [[ -z "${CURL_URL}" ]]; then
        return
    fi

    CURL_URL=$(echo "${CURL_URL}" | sed "s/%{subject}/$(echo "$2" | tr ' ' '+')/g")
    CURL_URL=$(echo "${CURL_URL}" | sed "s/%{content}/$(echo "$3" | tr ' ' '+')/g")
    CURL_OPTIONS=$(echo "${CURL_OPTIONS}" | sed "s/%{subject}/$2/g")
    CURL_OPTIONS=$(echo "${CURL_OPTIONS}" | sed "s/%{content}/$3/g")

    local CURL_COMMAND="curl -m 15 --retry 10 --retry-delay 1 -o /dev/null -s${CURL_OPTIONS:+" ${CURL_OPTIONS}"} \"${CURL_URL}\""

    if [[ "${PING_DEBUG}" == "TRUE" ]]; then
        color yellow "curl command: ${CURL_COMMAND}"
    fi

    eval "${CURL_COMMAND}"
    if [[ $? != 0 ]]; then
        color red "$1 ping sending has failed"
    else
        color blue "$1 ping has been sent successfully"
    fi
}

########################################
# Send notification.
# Arguments:
#     status (start / success / failure)
#     notification content
########################################
function send_notification() {
    local SUBJECT_START="${DISPLAY_NAME} Backup Start"
    local SUBJECT_SUCCESS="${DISPLAY_NAME} Backup Success"
    local SUBJECT_FAILURE="${DISPLAY_NAME} Backup Failed"

    case "$1" in
        start)
            # ping
            send_ping "start" "${SUBJECT_START}" "$2"
            ;;
        success)
            # mail
            if [[ "${MAIL_SMTP_ENABLE}" == "TRUE" && "${MAIL_WHEN_SUCCESS}" == "TRUE" ]]; then
                send_mail "${SUBJECT_SUCCESS}" "$2"
            fi
            # ping
            send_ping "success" "${SUBJECT_SUCCESS}" "$2"
            send_ping "completion" "${SUBJECT_SUCCESS}" "$2"
            ;;
        failure)
            # mail
            if [[ "${MAIL_SMTP_ENABLE}" == "TRUE" && "${MAIL_WHEN_FAILURE}" == "TRUE" ]]; then
                send_mail "${SUBJECT_FAILURE}" "$2"
            fi
            # ping
            send_ping "failure" "${SUBJECT_FAILURE}" "$2"
            send_ping "completion" "${SUBJECT_FAILURE}" "$2"
            ;;
    esac
}

########################################
# Configure PostgreSQL password file.
# Arguments:
#     None
########################################
function configure_postgresql() {
    if [[ "${DB_TYPE}" == "POSTGRESQL" ]]; then
        echo "${PG_HOST}:${PG_PORT}:${PG_DBNAME}:${PG_USERNAME}:${PG_PASSWORD}" > ~/.pgpass
        chmod 0600 ~/.pgpass
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
# Get RCLONE_REMOTE_LIST variables.
# Arguments:
#     None
# Outputs:
#     variable value
########################################
function get_rclone_remote_list() {
    # RCLONE_REMOTE_LIST
    RCLONE_REMOTE_LIST=()

    local i=0
    local RCLONE_REMOTE_NAME_X_REFER
    local RCLONE_REMOTE_DIR_X_REFER
    local RCLONE_REMOTE_X

    # for multiple
    while true; do
        RCLONE_REMOTE_NAME_X_REFER="RCLONE_REMOTE_NAME_${i}"
        RCLONE_REMOTE_DIR_X_REFER="RCLONE_REMOTE_DIR_${i}"
        get_env "${RCLONE_REMOTE_NAME_X_REFER}"
        get_env "${RCLONE_REMOTE_DIR_X_REFER}"

        if [[ -z "${!RCLONE_REMOTE_NAME_X_REFER}" || -z "${!RCLONE_REMOTE_DIR_X_REFER}" ]]; then
            break
        fi

        RCLONE_REMOTE_X=$(echo "${!RCLONE_REMOTE_NAME_X_REFER}:${!RCLONE_REMOTE_DIR_X_REFER}" | sed 's@\(/*\)$@@')
        RCLONE_REMOTE_LIST=(${RCLONE_REMOTE_LIST[@]} "${RCLONE_REMOTE_X}")

        ((i++))
    done
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
    init_env_db
    init_env_display
    init_env_ping
    init_env_mail

    # CRON
    get_env CRON
    CRON="${CRON:-"5 * * * *"}"

    # RCLONE_REMOTE_NAME
    get_env RCLONE_REMOTE_NAME
    RCLONE_REMOTE_NAME="${RCLONE_REMOTE_NAME:-"BitwardenBackup"}"
    RCLONE_REMOTE_NAME_0="${RCLONE_REMOTE_NAME}"

    # RCLONE_REMOTE_DIR
    get_env RCLONE_REMOTE_DIR
    RCLONE_REMOTE_DIR="${RCLONE_REMOTE_DIR:-"/BitwardenBackup/"}"
    RCLONE_REMOTE_DIR_0="${RCLONE_REMOTE_DIR}"

    # get RCLONE_REMOTE_LIST
    get_rclone_remote_list

    # RCLONE_GLOBAL_FLAG
    get_env RCLONE_GLOBAL_FLAG
    RCLONE_GLOBAL_FLAG="${RCLONE_GLOBAL_FLAG:-""}"

    # ZIP_ENABLE
    get_env ZIP_ENABLE
    if [[ "${ZIP_ENABLE^^}" == "FALSE" ]]; then
        ZIP_ENABLE="FALSE"
    else
        ZIP_ENABLE="TRUE"
    fi

    # ZIP_PASSWORD
    get_env ZIP_PASSWORD
    ZIP_PASSWORD="${ZIP_PASSWORD:-"WHEREISMYPASSWORD?"}"

    # ZIP_TYPE
    get_env ZIP_TYPE
    if [[ "${ZIP_TYPE,,}" == "7z" ]]; then
        ZIP_TYPE="7z"
    else
        ZIP_TYPE="zip"
    fi

    # BACKUP_KEEP_DAYS
    get_env BACKUP_KEEP_DAYS
    BACKUP_KEEP_DAYS="${BACKUP_KEEP_DAYS:-"0"}"

    # BACKUP_FILE_DATE_FORMAT
    get_env BACKUP_FILE_SUFFIX
    get_env BACKUP_FILE_DATE
    get_env BACKUP_FILE_DATE_SUFFIX
    BACKUP_FILE_DATE="$(echo "${BACKUP_FILE_DATE:-"%Y%m%d"}${BACKUP_FILE_DATE_SUFFIX}" | sed 's/[^0-9a-zA-Z%_-]//g')"
    BACKUP_FILE_DATE_FORMAT="$(echo "${BACKUP_FILE_SUFFIX:-"${BACKUP_FILE_DATE}"}" | sed 's/\///g')"

    # TIMEZONE
    get_env TIMEZONE
    local TIMEZONE_MATCHED_COUNT=$(ls "/usr/share/zoneinfo/${TIMEZONE}" 2> /dev/null | wc -l)
    if [[ "${TIMEZONE_MATCHED_COUNT}" -ne 1 ]]; then
        TIMEZONE="UTC"
    fi

    color yellow "========================================"
    color yellow "DATA_DIR: ${DATA_DIR}"
    color yellow "DATA_CONFIG: ${DATA_CONFIG}"
    color yellow "DATA_RSAKEY: ${DATA_RSAKEY}"
    color yellow "DATA_ATTACHMENTS: ${DATA_ATTACHMENTS}"
    color yellow "DATA_SENDS: ${DATA_SENDS}"
    color yellow "========================================"
    color yellow "DB_TYPE: ${DB_TYPE}"

    if [[ "${DB_TYPE}" == "POSTGRESQL" ]]; then
        color yellow "DB_URL: postgresql://${PG_USERNAME}:***(${#PG_PASSWORD} Chars)@${PG_HOST}:${PG_PORT}/${PG_DBNAME}"
    elif [[ "${DB_TYPE}" == "MYSQL" ]]; then
        color yellow "DB_URL: mysql://${MYSQL_USERNAME}:***(${#MYSQL_PASSWORD} Chars)@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}"
    else
        color yellow "DATA_DB: ${DATA_DB}"
    fi

    color yellow "========================================"
    color yellow "CRON: ${CRON}"

    for RCLONE_REMOTE_X in "${RCLONE_REMOTE_LIST[@]}"
    do
        color yellow "RCLONE_REMOTE: ${RCLONE_REMOTE_X}"
    done

    color yellow "RCLONE_GLOBAL_FLAG: ${RCLONE_GLOBAL_FLAG}"
    color yellow "ZIP_ENABLE: ${ZIP_ENABLE}"
    color yellow "ZIP_PASSWORD: ${#ZIP_PASSWORD} Chars"
    color yellow "ZIP_TYPE: ${ZIP_TYPE}"
    color yellow "BACKUP_FILE_DATE_FORMAT: ${BACKUP_FILE_DATE_FORMAT} (example \"[filename].$(date +"${BACKUP_FILE_DATE_FORMAT}").[ext]\")"
    color yellow "BACKUP_KEEP_DAYS: ${BACKUP_KEEP_DAYS}"
    if [[ -n "${PING_URL}" ]]; then
        color yellow "PING_URL: curl${PING_URL_CURL_OPTIONS:+" ${PING_URL_CURL_OPTIONS}"} \"${PING_URL}\""
    fi
    if [[ -n "${PING_URL_WHEN_START}" ]]; then
        color yellow "PING_URL_WHEN_START: curl${PING_URL_WHEN_START_CURL_OPTIONS:+" ${PING_URL_WHEN_START_CURL_OPTIONS}"} \"${PING_URL_WHEN_START}\""
    fi
    if [[ -n "${PING_URL_WHEN_SUCCESS}" ]]; then
        color yellow "PING_URL_WHEN_SUCCESS: curl${PING_URL_WHEN_SUCCESS_CURL_OPTIONS:+" ${PING_URL_WHEN_SUCCESS_CURL_OPTIONS}"} \"${PING_URL_WHEN_SUCCESS}\""
    fi
    if [[ -n "${PING_URL_WHEN_FAILURE}" ]]; then
        color yellow "PING_URL_WHEN_FAILURE: curl${PING_URL_WHEN_FAILURE_CURL_OPTIONS:+" ${PING_URL_WHEN_FAILURE_CURL_OPTIONS}"} \"${PING_URL_WHEN_FAILURE}\""
    fi
    color yellow "MAIL_SMTP_ENABLE: ${MAIL_SMTP_ENABLE}"
    if [[ "${MAIL_SMTP_ENABLE}" == "TRUE" ]]; then
        color yellow "MAIL_TO: ${MAIL_TO}"
        color yellow "MAIL_WHEN_SUCCESS: ${MAIL_WHEN_SUCCESS}"
        color yellow "MAIL_WHEN_FAILURE: ${MAIL_WHEN_FAILURE}"
    fi
    color yellow "TIMEZONE: ${TIMEZONE}"
    color yellow "DISPLAY_NAME: ${DISPLAY_NAME}"
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

function init_env_db() {
    # DB_TYPE
    get_env DB_TYPE

    if [[ "${DB_TYPE^^}" == "POSTGRESQL" ]]; then # postgresql
        DB_TYPE="POSTGRESQL"

        # PG_HOST
        get_env PG_HOST

        # PG_PORT
        get_env PG_PORT
        PG_PORT="${PG_PORT:-"5432"}"

        # PG_DBNAME
        get_env PG_DBNAME
        PG_DBNAME="${PG_DBNAME:-"vaultwarden"}"

        # PG_USERNAME
        get_env PG_USERNAME
        PG_USERNAME="${PG_USERNAME:-"vaultwarden"}"

        # PG_PASSWORD
        get_env PG_PASSWORD
    elif [[ "${DB_TYPE^^}" == "MYSQL" ]]; then # mysql
        DB_TYPE="MYSQL"

        # MYSQL_HOST
        get_env MYSQL_HOST

        # MYSQL_PORT
        get_env MYSQL_PORT
        MYSQL_PORT="${MYSQL_PORT:-"3306"}"

        # MYSQL_DATABASE
        get_env MYSQL_DATABASE
        MYSQL_DATABASE="${MYSQL_DATABASE:-"vaultwarden"}"

        # MYSQL_USERNAME
        get_env MYSQL_USERNAME
        MYSQL_USERNAME="${MYSQL_USERNAME:-"vaultwarden"}"

        # MYSQL_PASSWORD
        get_env MYSQL_PASSWORD

        # MYSQL_SSL
        get_env MYSQL_SSL

        # MYSQL_SSL_VERIFY_SERVER_CERT
        get_env MYSQL_SSL_VERIFY_SERVER_CERT

        # MYSQL_SSL_CA
        get_env MYSQL_SSL_CA

        # MYSQL_SSL_CERT
        get_env MYSQL_SSL_CERT

        # MYSQL_SSL_KEY
        get_env MYSQL_SSL_KEY
    else # sqlite
        DB_TYPE="SQLITE"
    fi
}

function init_env_display() {
    # DISPLAY_NAME
    get_env DISPLAY_NAME
    DISPLAY_NAME="${DISPLAY_NAME:-"vaultwarden"}"
}

function init_env_ping() {
    # PING_URL
    get_env PING_URL
    PING_URL="${PING_URL:-""}"

    # PING_URL_CURL_OPTIONS
    get_env PING_URL_CURL_OPTIONS
    PING_URL_CURL_OPTIONS="${PING_URL_CURL_OPTIONS:-""}"

    # PING_URL_WHEN_START
    get_env PING_URL_WHEN_START
    PING_URL_WHEN_START="${PING_URL_WHEN_START:-""}"

    # PING_URL_WHEN_START_CURL_OPTIONS
    get_env PING_URL_WHEN_START_CURL_OPTIONS
    PING_URL_WHEN_START_CURL_OPTIONS="${PING_URL_WHEN_START_CURL_OPTIONS:-""}"

    # PING_URL_WHEN_SUCCESS
    get_env PING_URL_WHEN_SUCCESS
    PING_URL_WHEN_SUCCESS="${PING_URL_WHEN_SUCCESS:-""}"

    # PING_URL_WHEN_SUCCESS_CURL_OPTIONS
    get_env PING_URL_WHEN_SUCCESS_CURL_OPTIONS
    PING_URL_WHEN_SUCCESS_CURL_OPTIONS="${PING_URL_WHEN_SUCCESS_CURL_OPTIONS:-""}"

    # PING_URL_WHEN_FAILURE
    get_env PING_URL_WHEN_FAILURE
    PING_URL_WHEN_FAILURE="${PING_URL_WHEN_FAILURE:-""}"

    # PING_URL_WHEN_FAILURE_CURL_OPTIONS
    get_env PING_URL_WHEN_FAILURE_CURL_OPTIONS
    PING_URL_WHEN_FAILURE_CURL_OPTIONS="${PING_URL_WHEN_FAILURE_CURL_OPTIONS:-""}"
}

function init_env_mail() {
    # MAIL_SMTP_ENABLE
    # MAIL_TO
    get_env MAIL_SMTP_ENABLE
    get_env MAIL_TO
    if [[ "${MAIL_SMTP_ENABLE^^}" == "TRUE" && "${MAIL_TO}" ]]; then
        MAIL_SMTP_ENABLE="TRUE"
    else
        MAIL_SMTP_ENABLE="FALSE"
    fi

    # MAIL_SMTP_VARIABLES
    get_env MAIL_SMTP_VARIABLES
    MAIL_SMTP_VARIABLES="${MAIL_SMTP_VARIABLES:-""}"

    # MAIL_WHEN_SUCCESS
    get_env MAIL_WHEN_SUCCESS
    if [[ "${MAIL_WHEN_SUCCESS^^}" == "FALSE" ]]; then
        MAIL_WHEN_SUCCESS="FALSE"
    else
        MAIL_WHEN_SUCCESS="TRUE"
    fi

    # MAIL_WHEN_FAILURE
    get_env MAIL_WHEN_FAILURE
    if [[ "${MAIL_WHEN_FAILURE^^}" == "FALSE" ]]; then
        MAIL_WHEN_FAILURE="FALSE"
    else
        MAIL_WHEN_FAILURE="TRUE"
    fi
}
