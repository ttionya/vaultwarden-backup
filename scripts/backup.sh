#!/bin/sh

. /app/includes.sh

NOW=$(date +"${BACKUP_FILE_DATE_FORMAT}")
# backup bitwarden_rs database file
BACKUP_FILE_DB="${BACKUP_DIR}/db.${NOW}.sqlite3"
# backup bitwarden_rs config file
BACKUP_FILE_CONFIG="${BACKUP_DIR}/config.${NOW}.json"
# backup bitwarden_rs attachments directory
BACKUP_FILE_ATTACHMENTS="${BACKUP_DIR}/attachments.${NOW}.tar"
# backup zip file
BACKUP_FILE_ZIP="${BACKUP_DIR}/backup.${NOW}.zip"

function clear_dir() {
    rm -rf ${BACKUP_DIR}
}

function backup_db() {
    color blue "backup bitwarden_rs sqlite database"

    if [[ -f "${DATA_DB}" ]]; then
        sqlite3 ${DATA_DB} ".backup ${BACKUP_FILE_DB}"
    else
        color yellow "not found bitwarden_rs sqlite database, skipping"
    fi
}

function backup_config() {
    color blue "backup bitwarden_rs config"

    if [[ -f "${DATA_CONFIG}" ]]; then
        cp -f ${DATA_DIR}/config.json ${BACKUP_FILE_CONFIG}
    else
        color yellow "not found bitwarden_rs config, skipping"
    fi
}

function backup_attachments() {
    color blue "backup bitwarden_rs attachments"

    local DATA_ATTACHMENTS="attachments"

    if [[ -d "${DATA_DIR}/${DATA_ATTACHMENTS}" ]]; then
        tar -c -C ${DATA_DIR} -f ${BACKUP_FILE_ATTACHMENTS} ${DATA_ATTACHMENTS}

        color blue "display attachments tar file list"

        tar -tf ${BACKUP_FILE_ATTACHMENTS}
    else
        color yellow "not found bitwarden_rs attachments directory, skipping"
    fi
}

function backup() {
    mkdir -p ${BACKUP_DIR}

    backup_db
    backup_config
    backup_attachments

    ls -lah ${BACKUP_DIR}
}

function backup_package() {
    if [[ "${ZIP_ENABLE}" == "TRUE" ]]; then
        color blue "package backup file"

        UPLOAD_FILE="${BACKUP_FILE_ZIP}"

        zip -jP ${ZIP_PASSWORD} ${BACKUP_FILE_ZIP} ${BACKUP_DIR}/*

        ls -lah ${BACKUP_DIR}

        color blue "display backup zip file list"

        zip -sf ${BACKUP_FILE_ZIP}
    else
        color yellow "skip package backup files"

        UPLOAD_FILE="${BACKUP_DIR}"
    fi
}

function upload() {
    color blue "upload backup file to storage system"

    # upload file not exist
    if [[ ! -f ${UPLOAD_FILE} ]]; then
        color red "upload file not found"

        send_mail_content "FALSE" "File upload failed at $(date +"%Y-%m-%d %H:%M:%S %Z"). Reason: Upload file not found."

        exit 1
    fi

    rclone copy ${UPLOAD_FILE} "${RCLONE_REMOTE}"
    if [[ $? != 0 ]]; then
        color red "upload failed"

        send_mail_content "FALSE" "File upload failed at $(date +"%Y-%m-%d %H:%M:%S %Z")."

        exit 1
    fi
}

function clear_history() {
    if [[ "${BACKUP_KEEP_DAYS}" -gt 0 ]]; then
        color blue "delete ${BACKUP_KEEP_DAYS} days ago backup files"

        local RCLONE_DELETE_LIST=$(rclone lsf "${RCLONE_REMOTE}" --min-age ${BACKUP_KEEP_DAYS}d)

        for RCLONE_DELETE_FILE in ${RCLONE_DELETE_LIST}
        do
            color yellow "deleting ${RCLONE_DELETE_FILE}"

            rclone delete "${RCLONE_REMOTE}/${RCLONE_DELETE_FILE}"
            if [[ $? != 0 ]]; then
                color red "delete ${RCLONE_DELETE_FILE} failed"
            fi
        done
    fi
}

color blue "running backup program..."

init_env
check_rclone_connection

clear_dir
backup
backup_package
upload
clear_dir
clear_history

send_mail_content "TRUE" "The file was successfully uploaded at $(date +"%Y-%m-%d %H:%M:%S %Z")."

color none ""
