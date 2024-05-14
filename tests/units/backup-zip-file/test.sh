#!/bin/bash

TEST_NAME="backup-zip-file"
TEST_OUTPUT_DIR="$(pwd)/${OUTPUTS_DIR}/${TEST_NAME}"

PASSWORD="71ad8764-2f69-4c0c-8452-61e08b9f489d"

color blue "Testing the ${TEST_NAME} unit..."

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
    color blue "Starting the test..."

    local BACKUP_FILE="${TEST_OUTPUT_DIR}/backup.test.zip"

    ls -l "${BACKUP_FILE}"
    if [[ -s "${BACKUP_FILE}" ]]; then
        color red "Error"
        ((ERROR_NUM++))
    fi

    7z l -p"${PASSWORD}" "${BACKUP_FILE}"
}

prepare
start
test
