#!/bin/bash

TEST_NAME="backup-db-sqlite-not-exists"
TEST_OUTPUT_DIR="$(pwd)/${OUTPUT_DIR}/${TEST_NAME}"
TEST_DATA_DIR="$(pwd)/${TEMP_DIR}/${TEST_NAME}"

PASSWORD="f4268105-b464-4b01-8987-d999bfbc5146"

FAILED_NUM=0

color yellow "Starting test case \"${TEST_NAME}\""

function prepare() {
    mkdir -p "${TEST_OUTPUT_DIR}" "${TEST_DATA_DIR}"
}

# function start() {
# }

function test() {
    color blue "Testing..."

    FOUND_MESSAGE_COUNT=$(docker run --rm \
        --mount "type=bind,source=${TEST_OUTPUT_DIR},target=${REMOTE_DIR}" \
        --mount "type=bind,source=${TEST_DATA_DIR},target=/bitwarden/data" \
        -e "RCLONE_REMOTE_DIR=${REMOTE_DIR}" \
        -e "ZIP_PASSWORD=${PASSWORD}" \
        -e "BACKUP_FILE_SUFFIX=test" \
        "${DOCKER_IMAGE}" \
        backup | grep -c "cannot access /bitwarden/data/db.sqlite3: No such file")

    if [[ "${FOUND_MESSAGE_COUNT}" -ne 1 ]]; then
        ((FAILED_NUM++))
    fi
}

function cleanup() {
    sudo rm -rf "${TEST_OUTPUT_DIR}" "${TEST_DATA_DIR}"

    unset TEST_OUTPUT_DIR
    unset TEST_DATA_DIR
    unset PASSWORD
    unset FOUND_MESSAGE_COUNT
}

prepare
# start
test
cleanup

test_result "${TEST_NAME}" "${FAILED_NUM}"
