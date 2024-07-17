#!/bin/bash

TEST_NAME="backup-zip-file"
TEST_OUTPUT_DIR="$(pwd)/${OUTPUT_DIR}/${TEST_NAME}"

PASSWORD="71ad8764-2f69-4c0c-8452-61e08b9f489d"
BACKUP_FILE="${TEST_OUTPUT_DIR}/backup.test.zip"

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

    ls -l "${BACKUP_FILE}"

    7z l -p"${PASSWORD}" "${BACKUP_FILE}"

    7z e -aoa -p"${PASSWORD}" -o"${EXTRACT_DIR}" "${BACKUP_FILE}"

    # TODO test the extracted files
}

prepare
start
test
