#!/bin/bash

TEST_NAME="check-encrypted-rclone-config"
TEST_OUTPUT_DIR="$(pwd)/${OUTPUT_DIR}/${TEST_NAME}"
TEST_EXTRACT_DIR="$(pwd)/${EXTRACT_DIR}/${TEST_NAME}"

PASSWORD="32d22daa-4e38-4c4c-8eeb-caf954d2259c"
BACKUP_FILE="${TEST_OUTPUT_DIR}/backup.test.zip"

FAILED_NUM=0

color yellow "Starting test case \"${TEST_NAME}\""

function prepare() {
    mkdir -p "${TEST_OUTPUT_DIR}" "${TEST_EXTRACT_DIR}"
}

function start() {
    docker run --rm \
        --mount "type=bind,source=${TEST_OUTPUT_DIR},target=${REMOTE_DIR}" \
        -e "RCLONE_REMOTE_DIR=${REMOTE_DIR}" \
        -e "RCLONE_GLOBAL_FLAG=--config /config/rclone/rclone.enc.conf" \
        -e "RCLONE_CONFIG_PASS=ttionya" \
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
      --mount "type=bind,source=${TEST_OUTPUT_DIR},target=/bitwarden/restore/" \
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
    unset PASSWORD
    unset BACKUP_FILE
}

prepare
start
test
cleanup

test_result "${TEST_NAME}" "${FAILED_NUM}"
