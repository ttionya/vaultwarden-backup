#!/bin/bash

. /app/includes.sh

# rclone command
if [[ "$1" == "rclone" ]]; then
    $*

    exit 0
fi

# mail test
if [[ "$1" == "mail" ]]; then
    export_env_file
    init_env_mail

    MAIL_SMTP_ENABLE="TRUE"
    MAIL_DEBUG="TRUE"

    if [[ -n "$2" ]]; then
        MAIL_TO="$2"
    fi

    send_mail "vaultwarden Backup Test" "Your SMTP configuration looks correct."

    exit 0
fi

# ping test
if [[ "$1" == "ping" ]]; then
    export_env_file
    init_env_ping

    PING_DEBUG="TRUE"

    send_ping "$2" "vaultwarden Backup Test" "Your PING configuration looks correct."

    exit 0
fi

# restore
if [[ "$1" == "restore" ]]; then
    . /app/restore.sh

    shift
    restore $*

    exit 0
fi

function configure_timezone() {
    ln -sf "/usr/share/zoneinfo/${TIMEZONE}" "${LOCALTIME_FILE}"
}

function configure_cron() {
    local FIND_CRON_COUNT="$(grep -c 'backup.sh' "${CRON_CONFIG_FILE}" 2> /dev/null)"
    if [[ "${FIND_CRON_COUNT}" -eq 0 ]]; then
        echo "${CRON} bash /app/backup.sh" >> "${CRON_CONFIG_FILE}"
    fi
}

init_env
check_rclone_connection all
configure_postgresql
configure_timezone
configure_cron

# backup manually
if [[ "$1" == "backup" ]]; then
    color yellow "Manually triggering a backup will only execute the backup script once, and the container will exit upon completion."

    bash "/app/backup.sh"

    exit 0
fi

# foreground run crond
exec /usr/bin/supercronic -passthrough-logs -quiet "${CRON_CONFIG_FILE}"
