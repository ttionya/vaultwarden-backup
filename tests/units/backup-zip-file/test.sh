#!/bin/bash

TEST_NAME="backup-zip-file"
TEST_OUTPUT_DIR="$(pwd)/${OUTPUT_DIR}/${TEST_NAME}"

PASSWORD="71ad8764-2f69-4c0c-8452-61e08b9f489d"
BACKUP_FILE="${TEST_OUTPUT_DIR}/backup.test.zip"

FAILED_NUM=0

color yellow "Starting test case \"${TEST_NAME}\""

function prepare() {
    mkdir -p "${TEST_OUTPUT_DIR}"
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

    7z e -aoa -p"${PASSWORD}" -o"${EXTRACT_DIR}" "${BACKUP_FILE}"

    check_files_same_in_folders "${DATA_DIR}" "${EXTRACT_DIR}"
    if [[ $? != 0 ]]; then
        ((FAILED_NUM++))
    fi
}

prepare
start
test

test_result "${TEST_NAME}" "${FAILED_NUM}"
