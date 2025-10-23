#!/bin/bash

# When verifying the Rclone connection, the previous method ensured
# the remote directory existed by creating it (mkdir), which requires special permissions on S3.
# It has been changed to attempt listing the remote directory (lsd) to avoid this issue.
# If listing the directory fails, the directory is considered non-existent and will be created.
# See issue https://github.com/ttionya/vaultwarden-backup/issues/199 for details.
#
# This test case verifies that the remote directory can be created correctly without affecting the backup operation.

TEST_NAME="check-rclone-connection-initializing"
TEST_OUTPUT_DIR="$(pwd)/${OUTPUT_DIR}/${TEST_NAME}"
TEST_EXTRACT_DIR="$(pwd)/${EXTRACT_DIR}/${TEST_NAME}"
TEST_DIR="/folder1/folder2/folder3"
TEST_REMOTE_DIR="${REMOTE_DIR}${TEST_DIR}"

PASSWORD="9eeef525-24e9-496b-9e32-990211dce6eb"
BACKUP_FILE="${TEST_OUTPUT_DIR}${TEST_DIR}/backup.test.zip"

FAILED_NUM=0

color yellow "Starting test case \"${TEST_NAME}\""

function prepare() {
    mkdir -p "${TEST_OUTPUT_DIR}" "${TEST_EXTRACT_DIR}"
}

function start() {
    docker run --rm \
        --mount "type=bind,source=${TEST_OUTPUT_DIR},target=${REMOTE_DIR}" \
        -e "RCLONE_REMOTE_DIR=${TEST_REMOTE_DIR}" \
        -e "ZIP_PASSWORD=${PASSWORD}" \
        -e "BACKUP_FILE_SUFFIX=test" \
        "${DOCKER_IMAGE}" \
        backup
}

function test() {
    color blue "Testing..."

    ls -l "${BACKUP_FILE}"

    7z l -p"${PASSWORD}" "${BACKUP_FILE}"

    docker run --rm \
      --mount "type=bind,source=${TEST_EXTRACT_DIR},target=/bitwarden/data/" \
      --mount "type=bind,source=$(dirname "${BACKUP_FILE}"),target=/bitwarden/restore/" \
      "${DOCKER_IMAGE}" \
      restore \
      -f \
      -p "${PASSWORD}" \
      --zip-file "$(basename "${BACKUP_FILE}")"

    check_files_same_in_folders "${DATA_DIR}" "${TEST_EXTRACT_DIR}"
    if [[ $? != 0 ]]; then
        ((FAILED_NUM++))
    fi
}

function cleanup() {
    sudo rm -rf "${TEST_OUTPUT_DIR}" "${TEST_EXTRACT_DIR}"

    unset TEST_OUTPUT_DIR
    unset TEST_EXTRACT_DIR
    unset TEST_DIR
    unset TEST_REMOTE_DIR
    unset PASSWORD
    unset BACKUP_FILE
}

prepare
start
test
cleanup

test_result "${TEST_NAME}" "${FAILED_NUM}"
