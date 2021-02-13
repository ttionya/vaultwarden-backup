#!/bin/sh

. /app/includes.sh

# rclone command
if [[ "$1" == "rclone" ]]; then
    $*

    exit 0
fi

# mailx test
if [[ "$1" == "mail" ]]; then
    MAIL_SMTP_ENABLE="TRUE"
    MAIL_DEBUG="TRUE"

    if [[ -n "$2" ]]; then
        MAIL_TO="$2"
    fi

    init_env

    send_mail "EteBase Backup Test" "Your SMTP looks configured correctly."

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
    if [[ ! -f /etc/localtime || ! -f /etc/timezone ]]; then
        cp -f /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
        echo "${TIMEZONE}" > /etc/timezone
    fi
}

function configure_cron() {
    local FIND_CRON_COUNT=$(crontab -l | grep -c 'backup.sh')
    if [[ ${FIND_CRON_COUNT} -eq 0 ]]; then
        echo "${CRON} sh /app/backup.sh > /dev/stdout" >> /etc/crontabs/root
    fi
}

init_env
check_rclone_connection
configure_timezone
configure_cron

# foreground run crond
crond -l 2 -f
