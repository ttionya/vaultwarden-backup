#!/bin/bash

echo "Test backup-zip-file"

mkdir -p outputs/backup-zip-file

docker run --rm \
  --mount type=bind,source=$(pwd)/outputs/backup-zip-file,target=/outputs \
  -e RCLONE_REMOTE_DIR=/outputs \
  ttionya/vaultwarden-backup:test \
  backup

ls -l outputs/backup-zip-file
