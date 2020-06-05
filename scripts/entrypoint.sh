#!/bin/sh

. /app/includes.sh

function configure_cron() {
    echo "${CRON} sh /app/backup.sh > /dev/stdout" >> /etc/crontabs/root
}

init_env
check_rclone_connection
configure_cron

# foreground run crond
crond -l 2 -f
