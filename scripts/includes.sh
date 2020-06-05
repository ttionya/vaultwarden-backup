#!/bin/sh

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
        none)    echo $2 ;;
    esac
}

########################################
# Check storage system connection success.
# Arguments:
#     None
########################################
function check_rclone_connection() {
    rclone mkdir ${RCLONE_REMOTE}
    if [[ $? != 0 ]]; then
        color red "storage system connection failure"
        exit 1
    fi
}

########################################
# Initialization environment variables.
# Arguments:
#     None
# Outputs:
#     environment variables
########################################
function init_env() {
    # CRON
    local CRON_DEFAULT="5 * * * *"
    if [[ -z "${CRON}" ]]; then
        CRON="${CRON_DEFAULT}"
    fi

    # RCLONE_REMOTE_NAME
    local RCLONE_REMOTE_NAME_DEFAULT="BitwardenBackup"
    if [[ -z "${RCLONE_REMOTE_NAME}" ]]; then
        RCLONE_REMOTE_NAME="${RCLONE_REMOTE_NAME_DEFAULT}"
    fi

    # RCLONE_REMOTE_DIR
    local RCLONE_REMOTE_DIR_DEFAULT="/BitwardenBackup/"
    if [[ -z "${RCLONE_REMOTE_DIR}" ]]; then
        RCLONE_REMOTE_DIR="${RCLONE_REMOTE_DIR_DEFAULT}"
    fi

    # RCLONE_REMOTE
    RCLONE_REMOTE="${RCLONE_REMOTE_NAME}:${RCLONE_REMOTE_DIR}"

    # ZIP_ENABLE
    if [[ $(echo "${ZIP_ENABLE}" | tr '[a-z]' '[A-Z]') == "FALSE" ]]; then
        ZIP_ENABLE="FALSE"
    else
        ZIP_ENABLE="TRUE"
    fi

    # ZIP_PASSWORD
    if [[ -z "${ZIP_PASSWORD}" ]]; then
        ZIP_PASSWORD="WHEREISMYPASSWORD?"
    fi

    # BACKUP_KEEP_DAYS
    local BACKUP_KEEP_DAYS_DEFAULT="0"
    if [[ -z "${BACKUP_KEEP_DAYS}" ]]; then
        BACKUP_KEEP_DAYS="${BACKUP_KEEP_DAYS_DEFAULT}"
    fi

    color yellow "========================================"
    color yellow "CRON: ${CRON}"
    color yellow "RCLONE_REMOTE_NAME: ${RCLONE_REMOTE_NAME}"
    color yellow "RCLONE_REMOTE_DIR: ${RCLONE_REMOTE_DIR}"
    color yellow "RCLONE_REMOTE: ${RCLONE_REMOTE}"
    color yellow "ZIP_ENABLE: ${ZIP_ENABLE}"
    color yellow "ZIP_PASSWORD: ${#ZIP_PASSWORD} Chars"
    color yellow "BACKUP_KEEP_DAYS: ${BACKUP_KEEP_DAYS}"
    color yellow "========================================"
}
