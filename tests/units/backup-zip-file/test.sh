#!/bin/bash

TEST_NAME="backup-zip-file"
TEST_OUTPUT_DIR="$(pwd)/${OUTPUT_DIR}/${TEST_NAME}"
TEST_EXTRACT_DIR="$(pwd)/${EXTRACT_DIR}/${TEST_NAME}"

PASSWORD="71ad8764-2f69-4c0c-8452-61e08b9f489d"
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
    rm -rf "${TEST_OUTPUT_DIR}" "${TEST_EXTRACT_DIR}"

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
