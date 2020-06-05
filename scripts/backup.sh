#!/bin/sh

. /app/includes.sh

BACKUP_DIR="/bitwarden/backup/"
BACKUP_FILE="${BACKUP_DIR}/backup.$(date +%Y%m%d).sqlite3"
BACKUP_FILE_ZIP="${BACKUP_FILE}.zip"

function backup_clear_dir() {
    rm -rf ${BACKUP_DIR}
}

function backup() {
    color blue "backup bitwarden_rs sqlite database"

    mkdir -p ${BACKUP_DIR}

    sqlite3 /bitwarden/data/db.sqlite3 ".backup ${BACKUP_FILE}"

    ls -lah ${BACKUP_DIR}
}

function backup_package() {
    if [[ "${ZIP_ENABLE}" == "TRUE" ]]; then
        color blue "package backup file"
        UPLOAD_FILE="${BACKUP_FILE_ZIP}"

        zip -jP ${ZIP_PASSWORD} ${BACKUP_FILE_ZIP} ${BACKUP_FILE}

        ls -lah ${BACKUP_DIR}
    else
        color yellow "skip package backup file"
        UPLOAD_FILE="${BACKUP_FILE}"
    fi
}

function backup_upload() {
    color blue "upload backup file to storage system"

    rclone copy ${UPLOAD_FILE} ${RCLONE_REMOTE}
    if [[ $? != 0 ]]; then
        color red "upload failed"
        exit 1
    fi
}

function backup_clear_history() {
    if [[ "${BACKUP_KEEP_DAYS}" -gt 0 ]]; then
        color blue "delete ${BACKUP_KEEP_DAYS} days ago backup files"

        RCLONE_DELETE_LIST=$(rclone lsf ${RCLONE_REMOTE} | head -n -${BACKUP_KEEP_DAYS})

        for RCLONE_DELETE_FILE in ${RCLONE_DELETE_LIST}
        do
            color yellow "deleting ${RCLONE_DELETE_FILE}"

            rclone delete ${RCLONE_REMOTE}/${RCLONE_DELETE_FILE}
            if [[ $? != 0 ]]; then
                color red "delete ${RCLONE_DELETE_FILE} failed"
            fi
        done
    fi
}

color blue "running backup program..."

init_env
check_rclone_connection

backup_clear_dir
backup
backup_package
backup_upload
backup_clear_dir
backup_clear_history

color none ""
