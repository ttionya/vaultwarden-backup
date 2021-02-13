#!/bin/sh

. /app/includes.sh

TODAY=$(date +%Y%m%d)
# backup etebase database file
BACKUP_FILE_DB="${BACKUP_DIR}/db.${TODAY}.sqlite3"
# backup etebase config file
BACKUP_FILE_CONFIG="${BACKUP_DIR}/etebase-server.${TODAY}.ini"
# backup etebase media directory
BACKUP_FILE_MEDIA="${BACKUP_DIR}/media.${TODAY}.tar"
# backup etebase secret file
BACKUP_FILE_SECRET="${BACKUP_DIR}/secret.${TODAY}.txt"
# backup zip file
BACKUP_FILE_ZIP="${BACKUP_DIR}/backup-etebase.${TODAY}.zip"

function clear_dir() {
    rm -rf ${BACKUP_DIR}
}

function backup_db() {
    color blue "backup etebase sqlite database"

    if [[ -f "${DATA_DB}" ]]; then
        sqlite3 ${DATA_DB} ".backup ${BACKUP_FILE_DB}"
    else
        color yellow "not found etebase sqlite database, skipping"
    fi
}

function backup_config() {
    color blue "backup etebase config"

    if [[ -f "${DATA_CONFIG}" ]]; then
        cp -f ${DATA_CONFIG} ${BACKUP_FILE_CONFIG}
    else
        color yellow "not found etebase config, skipping"
    fi
}

function backup_media() {
    color blue "backup etebase media"

    local DATA_MEDIA="media"

    if [[ -d "${DATA_DIR}/${DATA_MEDIA}" ]]; then
        tar -c -C ${DATA_DIR} -f ${BACKUP_FILE_MEDIA} ${DATA_MEDIA}

        color blue "display media tar file list"

        tar -tf ${BACKUP_FILE_MEDIA}
    else
        color yellow "not found etebase media directory, skipping"
    fi
}

function backup_secret() {
    color blue "backup etebase config"

    if [[ -f "${DATA_SECRET}" ]]; then
        cp -f ${DATA_SECRET} ${BACKUP_FILE_SECRET}
    else
        color yellow "not found etebase secret, skipping"
    fi
}

function backup() {
    mkdir -p ${BACKUP_DIR}

    backup_db
    backup_config
    backup_media
    backup_secret

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

    rclone copy ${UPLOAD_FILE} ${RCLONE_REMOTE}
    if [[ $? != 0 ]]; then
        color red "upload failed"

        send_mail_content "FALSE" "File upload failed at $(date +"%Y-%m-%d %H:%M:%S %Z")."

        exit 1
    fi
}

function clear_history() {
    if [[ "${BACKUP_KEEP_DAYS}" -gt 0 ]]; then
        color blue "delete ${BACKUP_KEEP_DAYS} days ago backup files"

        local RCLONE_DELETE_LIST=$(rclone lsf ${RCLONE_REMOTE} | head -n -${BACKUP_KEEP_DAYS})

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

clear_dir
backup
backup_package
upload
clear_dir
clear_history

send_mail_content "TRUE" "The file was successfully uploaded at $(date +"%Y-%m-%d %H:%M:%S %Z")."

color none ""
