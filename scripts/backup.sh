#!/bin/bash

. /app/includes.sh

function clear_dir() {
    rm -rf "${BACKUP_DIR}"
}

function backup_init() {
    NOW="$(date +"${BACKUP_FILE_DATE_FORMAT}")"
    # backup vaultwarden database file (sqlite)
    BACKUP_FILE_DB_SQLITE="${BACKUP_DIR}/db.${NOW}.sqlite3"
    # backup vaultwarden database file (postgresql)
    BACKUP_FILE_DB_POSTGRESQL="${BACKUP_DIR}/db.${NOW}.dump"
    # backup vaultwarden database file (mysql)
    BACKUP_FILE_DB_MYSQL="${BACKUP_DIR}/db.${NOW}.sql"
    # backup vaultwarden config file
    BACKUP_FILE_CONFIG="${BACKUP_DIR}/config.${NOW}.json"
    # backup vaultwarden rsakey files
    BACKUP_FILE_RSAKEY="${BACKUP_DIR}/rsakey.${NOW}.tar"
    # backup vaultwarden attachments directory
    BACKUP_FILE_ATTACHMENTS="${BACKUP_DIR}/attachments.${NOW}.tar"
    # backup vaultwarden sends directory
    BACKUP_FILE_SENDS="${BACKUP_DIR}/sends.${NOW}.tar"
    # backup zip file
    BACKUP_FILE_ZIP="${BACKUP_DIR}/backup.${NOW}.${ZIP_TYPE}"
}

function backup_db_sqlite() {
    color blue "backup vaultwarden sqlite database"

    check_file_exist "${DATA_DB}"

    sqlite3 "${DATA_DB}" ".backup '${BACKUP_FILE_DB_SQLITE}'"
    if [[ $? != 0 ]]; then
        color red "backup vaultwarden sqlite database failed"

        send_notification "failure" "Backup failed at $(date +"%Y-%m-%d %H:%M:%S %Z"). Reason: Backup sqlite database failed."

        exit 1
    fi
}

function backup_db_postgresql() {
    color blue "backup vaultwarden postgresql database"

    pg_dump -Fc -h "${PG_HOST}" -p "${PG_PORT}" -d "${PG_DBNAME}" -U "${PG_USERNAME}" -f "${BACKUP_FILE_DB_POSTGRESQL}"
    if [[ $? != 0 ]]; then
        color red "backup vaultwarden postgresql database failed"

        send_notification "failure" "Backup failed at $(date +"%Y-%m-%d %H:%M:%S %Z"). Reason: Backup postgresql database failed."

        exit 1
    fi
}

function backup_db_mysql() {
    color blue "backup vaultwarden mysql database"

    local EXTRA_OPTIONS=()
    if [[ -n "${MYSQL_SSL}" ]]; then
        EXTRA_OPTIONS+=("--ssl=\"${MYSQL_SSL}\"")
    fi
    if [[ -n "${MYSQL_SSL_VERIFY_SERVER_CERT}" ]]; then
        EXTRA_OPTIONS+=("--ssl-verify-server-cert=\"${MYSQL_SSL_VERIFY_SERVER_CERT}\"")
    fi
    if [[ -n "${MYSQL_SSL_CA}" ]]; then
        EXTRA_OPTIONS+=("--ssl-ca=\"${MYSQL_SSL_CA}\"")
    fi
    if [[ -n "${MYSQL_SSL_CERT}" ]]; then
        EXTRA_OPTIONS+=("--ssl-cert=\"${MYSQL_SSL_CERT}\"")
    fi
    if [[ -n "${MYSQL_SSL_KEY}" ]]; then
        EXTRA_OPTIONS+=("--ssl-key=\"${MYSQL_SSL_KEY}\"")
    fi

    eval "mariadb-dump -h \"${MYSQL_HOST}\" -P \"${MYSQL_PORT}\" -u \"${MYSQL_USERNAME}\" -p\"${MYSQL_PASSWORD}\" ${EXTRA_OPTIONS[@]} \"${MYSQL_DATABASE}\" > \"${BACKUP_FILE_DB_MYSQL}\""
    if [[ $? != 0 ]]; then
        color red "backup vaultwarden mysql database failed"

        send_notification "failure" "Backup failed at $(date +"%Y-%m-%d %H:%M:%S %Z"). Reason: Backup mysql database failed."

        exit 1
    fi
}

function backup_config() {
    color blue "backup vaultwarden config"

    if [[ -f "${DATA_CONFIG}" ]]; then
        cp -f "${DATA_CONFIG}" "${BACKUP_FILE_CONFIG}"
    else
        color yellow "not found vaultwarden config, skipping"
    fi
}

function backup_rsakey() {
    color blue "backup vaultwarden rsakey"

    local FIND_RSAKEY=$(find "${DATA_RSAKEY_DIRNAME}" -name "${DATA_RSAKEY_BASENAME}*" | xargs -I {} basename {})
    local FIND_RSAKEY_COUNT=$(echo "${FIND_RSAKEY}" | wc -l)

    if [[ "${FIND_RSAKEY_COUNT}" -gt 0 ]]; then
        echo "${FIND_RSAKEY}" | tar -c -C "${DATA_RSAKEY_DIRNAME}" -f "${BACKUP_FILE_RSAKEY}" -T -

        color blue "display rsakey tar file list"

        tar -tf "${BACKUP_FILE_RSAKEY}"
    else
        color yellow "not found vaultwarden rsakey, skipping"
    fi
}

function backup_attachments() {
    color blue "backup vaultwarden attachments"

    if [[ -d "${DATA_ATTACHMENTS}" ]]; then
        tar -c -C "${DATA_ATTACHMENTS_DIRNAME}" -f "${BACKUP_FILE_ATTACHMENTS}" "${DATA_ATTACHMENTS_BASENAME}"

        color blue "display attachments tar file list"

        tar -tf "${BACKUP_FILE_ATTACHMENTS}"
    else
        color yellow "not found vaultwarden attachments directory, skipping"
    fi
}

function backup_sends() {
    color blue "backup vaultwarden sends"

    if [[ -d "${DATA_SENDS}" ]]; then
        tar -c -C "${DATA_SENDS_DIRNAME}" -f "${BACKUP_FILE_SENDS}" "${DATA_SENDS_BASENAME}"

        color blue "display sends tar file list"

        tar -tf "${BACKUP_FILE_SENDS}"
    else
        color yellow "not found vaultwarden sends directory, skipping"
    fi
}

function backup() {
    mkdir -p "${BACKUP_DIR}"

    case "${DB_TYPE}" in
        SQLITE)     backup_db_sqlite ;;
        POSTGRESQL) backup_db_postgresql ;;
        MYSQL)      backup_db_mysql ;;
    esac

    backup_config
    backup_rsakey
    backup_attachments
    backup_sends

    ls -lah "${BACKUP_DIR}"
}

function backup_package() {
    if [[ "${ZIP_ENABLE}" == "TRUE" ]]; then
        color blue "package backup file"

        UPLOAD_FILE="${BACKUP_FILE_ZIP}"

        if [[ "${ZIP_TYPE}" == "zip" ]]; then
            7z a -tzip -mx=9 -p"${ZIP_PASSWORD}" "${BACKUP_FILE_ZIP}" "${BACKUP_DIR}"/*
        else
            7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on -mhe=on -p"${ZIP_PASSWORD}" "${BACKUP_FILE_ZIP}" "${BACKUP_DIR}"/*
        fi

        ls -lah "${BACKUP_DIR}"

        color blue "display backup ${ZIP_TYPE} file list"

        7z l -p"${ZIP_PASSWORD}" "${BACKUP_FILE_ZIP}"
    else
        color yellow "skip package backup files"

        UPLOAD_FILE="${BACKUP_DIR}"
    fi
}

function upload() {
    # upload file not exist
    if [[ ! -e "${UPLOAD_FILE}" ]]; then
        color red "upload file not found"

        send_notification "failure" "File upload failed at $(date +"%Y-%m-%d %H:%M:%S %Z"). Reason: Upload file not found."

        exit 1
    fi

    # upload
    local HAS_ERROR="FALSE"

    for RCLONE_REMOTE_X in "${RCLONE_REMOTE_LIST[@]}"
    do
        color blue "upload backup file to storage system $(color yellow "[${RCLONE_REMOTE_X}]")"

        rclone ${RCLONE_GLOBAL_FLAG} copy "${UPLOAD_FILE}" "${RCLONE_REMOTE_X}"
        if [[ $? != 0 ]]; then
            color red "upload failed"

            HAS_ERROR="TRUE"
        fi
    done

    if [[ "${HAS_ERROR}" == "TRUE" ]]; then
        send_notification "failure" "File upload failed at $(date +"%Y-%m-%d %H:%M:%S %Z")."

        exit 1
    fi
}

function clear_history() {
    # If all retention variables are 0, retention is disabled
    if [[ "${BACKUP_KEEP_DAYS}" -eq 0 && "${BACKUP_KEEP_WEEKS}" -eq 0 && "${BACKUP_KEEP_MONTHS}" -eq 0 && "${BACKUP_KEEP_YEARS}" -eq 0 && "${BACKUP_KEEP_LAST}" -eq 0 ]]; then
        color yellow "retention policy disabled (all BACKUP_KEEP_* are 0), skipping history cleanup"
        return 0
    fi

    for RCLONE_REMOTE_X in "${RCLONE_REMOTE_LIST[@]}"
    do
        color blue "evaluating retention policy on storage system $(color yellow "[${RCLONE_REMOTE_X}]")"

        mapfile -t RCLONE_REMOTE_FILES < <(rclone ${RCLONE_GLOBAL_FLAG} lsf "${RCLONE_REMOTE_X}" --files-only --format "tp" --time-format "2006-01-02 15:04:05" --separator ";")

        if [[ "${#RCLONE_REMOTE_FILES[@]}" -eq 0 ]]; then
            color yellow "no files found on remote [${RCLONE_REMOTE_X}]"
            continue
        fi

        # Parse backup files and group by snapshot
        declare -A SNAPSHOT_TIMESTAMP=()
        declare -A SNAPSHOT_FILES=()
        local SNAPSHOT_IDS=()

        local SUFFIX_REGEX="${BACKUP_FILE_SUFFIX_REGEX:-}"
        if [[ -z "${SUFFIX_REGEX}" ]]; then
            SUFFIX_REGEX="$(date_format_to_regex "${BACKUP_FILE_DATE_FORMAT}")"
        fi

        for FILE_ENTRY in "${RCLONE_REMOTE_FILES[@]}"; do
            [[ -z "${FILE_ENTRY}" ]] && continue

            local FILE_TS="${FILE_ENTRY%%;*}"
            local FILE_NAME="${FILE_ENTRY#*;}"
            local SNAP_ID=""

            if [[ "${FILE_NAME}" =~ ^backup\.(.+)\.(zip|7z)$ ]]; then
                local SUFFIX="${BASH_REMATCH[1]}"
                if [[ "${SUFFIX}" =~ ^${SUFFIX_REGEX}$ ]]; then
                    SNAP_ID="pkg_${SUFFIX}"
                fi
            elif [[ "${FILE_NAME}" =~ ^db\.(.+)\.(sqlite3|dump|sql)$ ]]; then
                local SUFFIX="${BASH_REMATCH[1]}"
                if [[ "${SUFFIX}" =~ ^${SUFFIX_REGEX}$ ]]; then
                    SNAP_ID="unpacked_${SUFFIX}"
                fi
            elif [[ "${FILE_NAME}" =~ ^config\.(.+)\.json$ ]]; then
                local SUFFIX="${BASH_REMATCH[1]}"
                if [[ "${SUFFIX}" =~ ^${SUFFIX_REGEX}$ ]]; then
                    SNAP_ID="unpacked_${SUFFIX}"
                fi
            elif [[ "${FILE_NAME}" =~ ^(rsakey|attachments|sends)\.(.+)\.tar$ ]]; then
                local SUFFIX="${BASH_REMATCH[2]}"
                if [[ "${SUFFIX}" =~ ^${SUFFIX_REGEX}$ ]]; then
                    SNAP_ID="unpacked_${SUFFIX}"
                fi
            fi

            if [[ -z "${SNAP_ID}" ]]; then
                # Non-backup file or suffix mismatch, ignore
                continue
            fi

            if [[ -z "${SNAPSHOT_TIMESTAMP[${SNAP_ID}]:-}" ]]; then
                SNAPSHOT_TIMESTAMP["${SNAP_ID}"]="${FILE_TS}"
                SNAPSHOT_FILES["${SNAP_ID}"]="${FILE_NAME}"
                SNAPSHOT_IDS+=("${SNAP_ID}")
            else
                SNAPSHOT_FILES["${SNAP_ID}"]="${SNAPSHOT_FILES[${SNAP_ID}]} ${FILE_NAME}"
            fi
        done

        if [[ "${#SNAPSHOT_IDS[@]}" -eq 0 ]]; then
            color yellow "no matching backup files found on remote [${RCLONE_REMOTE_X}]"
            continue
        fi

        # Sort snapshots chronologically descending (newest first)
        local SORTED_SNAPSHOTS=()
        mapfile -t SORTED_SNAPSHOTS < <(
            for SNAP_ID in "${SNAPSHOT_IDS[@]}"; do
                echo "${SNAPSHOT_TIMESTAMP[${SNAP_ID}]};${SNAP_ID}"
            done | sort -r
        )

        declare -A KEPT_SNAPSHOTS=()
        declare -A SEEN_DAYS=()
        declare -A SEEN_WEEKS=()
        declare -A SEEN_MONTHS=()
        declare -A SEEN_YEARS=()
        local LAST_COUNT=0

        for SNAP_LINE in "${SORTED_SNAPSHOTS[@]}"; do
            [[ -z "${SNAP_LINE}" ]] && continue

            local SNAP_TS="${SNAP_LINE%%;*}"
            local SNAP_ID="${SNAP_LINE#*;}"
            local KEEP_THIS="FALSE"
            local REASONS=()

            # 1. Keep Last N
            if [[ "${BACKUP_KEEP_LAST}" -gt 0 && "${LAST_COUNT}" -lt "${BACKUP_KEEP_LAST}" ]]; then
                KEEP_THIS="TRUE"
                ((LAST_COUNT++))
                REASONS+=("last (${LAST_COUNT}/${BACKUP_KEEP_LAST})")
            fi

            local DAY_KEY="${SNAP_TS:0:10}"
            local MONTH_KEY="${SNAP_TS:0:7}"
            local YEAR_KEY="${SNAP_TS:0:4}"
            local DATE_INPUT="${SNAP_TS:0:10} ${SNAP_TS:11:8}"
            local WEEK_KEY
            WEEK_KEY=$(date -d "${DATE_INPUT}" +"%G-W%V" 2>/dev/null)
            if [[ -z "${WEEK_KEY}" ]]; then
                WEEK_KEY="${DAY_KEY}"
            fi

            # 2. Keep Daily
            if [[ "${BACKUP_KEEP_DAYS}" -gt 0 ]]; then
                if [[ -z "${SEEN_DAYS[${DAY_KEY}]:-}" && "${#SEEN_DAYS[@]}" -lt "${BACKUP_KEEP_DAYS}" ]]; then
                    SEEN_DAYS["${DAY_KEY}"]="1"
                    KEEP_THIS="TRUE"
                    REASONS+=("daily (${#SEEN_DAYS[@]}/${BACKUP_KEEP_DAYS} - ${DAY_KEY})")
                fi
            fi

            # 3. Keep Weekly
            if [[ "${BACKUP_KEEP_WEEKS}" -gt 0 ]]; then
                if [[ -z "${SEEN_WEEKS[${WEEK_KEY}]:-}" && "${#SEEN_WEEKS[@]}" -lt "${BACKUP_KEEP_WEEKS}" ]]; then
                    SEEN_WEEKS["${WEEK_KEY}"]="1"
                    KEEP_THIS="TRUE"
                    REASONS+=("weekly (${#SEEN_WEEKS[@]}/${BACKUP_KEEP_WEEKS} - ${WEEK_KEY})")
                fi
            fi

            # 4. Keep Monthly
            if [[ "${BACKUP_KEEP_MONTHS}" -gt 0 ]]; then
                if [[ -z "${SEEN_MONTHS[${MONTH_KEY}]:-}" && "${#SEEN_MONTHS[@]}" -lt "${BACKUP_KEEP_MONTHS}" ]]; then
                    SEEN_MONTHS["${MONTH_KEY}"]="1"
                    KEEP_THIS="TRUE"
                    REASONS+=("monthly (${#SEEN_MONTHS[@]}/${BACKUP_KEEP_MONTHS} - ${MONTH_KEY})")
                fi
            fi

            # 5. Keep Yearly
            if [[ "${BACKUP_KEEP_YEARS}" -gt 0 ]]; then
                if [[ -z "${SEEN_YEARS[${YEAR_KEY}]:-}" && "${#SEEN_YEARS[@]}" -lt "${BACKUP_KEEP_YEARS}" ]]; then
                    SEEN_YEARS["${YEAR_KEY}"]="1"
                    KEEP_THIS="TRUE"
                    REASONS+=("yearly (${#SEEN_YEARS[@]}/${BACKUP_KEEP_YEARS} - ${YEAR_KEY})")
                fi
            fi

            local REASON_STR
            REASON_STR="$(IFS=", "; echo "${REASONS[*]}")"

            if [[ "${KEEP_THIS}" == "TRUE" ]]; then
                KEPT_SNAPSHOTS["${SNAP_ID}"]="1"
                for SNAP_FILE in ${SNAPSHOT_FILES[${SNAP_ID}]}; do
                    color blue "keeping backup \"${SNAP_FILE}\" (${SNAP_TS:0:19}) -> ${REASON_STR}"
                done
            else
                for SNAP_FILE in ${SNAPSHOT_FILES[${SNAP_ID}]}; do
                    color yellow "pruning expired backup \"${SNAP_FILE}\" (${SNAP_TS:0:19})"
                done
            fi
        done

        # Delete unkept files
        for SNAP_ID in "${SNAPSHOT_IDS[@]}"; do
            if [[ -z "${KEPT_SNAPSHOTS[${SNAP_ID}]:-}" ]]; then
                for DEL_FILE in ${SNAPSHOT_FILES[${SNAP_ID}]}; do
                    color yellow "deleting \"${DEL_FILE}\""
                    rclone ${RCLONE_GLOBAL_FLAG} delete "${RCLONE_REMOTE_X}/${DEL_FILE}"
                    if [[ $? != 0 ]]; then
                        color red "delete \"${DEL_FILE}\" failed"
                    fi
                done
            fi
        done
    done
}

color blue "running the backup program at $(date +"%Y-%m-%d %H:%M:%S %Z")"

init_env

send_notification "start" "Start backup at $(date +"%Y-%m-%d %H:%M:%S %Z")"

check_rclone_connection any

clear_dir
backup_init
backup
backup_package
upload
clear_dir
clear_history

send_notification "success" "The file was successfully uploaded at $(date +"%Y-%m-%d %H:%M:%S %Z")."

color none ""