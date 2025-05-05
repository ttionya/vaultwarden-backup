#!/bin/bash

TEST_NAME="backup-unpackage"
TEST_OUTPUT_DIR="$(pwd)/${OUTPUT_DIR}/${TEST_NAME}"
TEST_EXTRACT_DIR="$(pwd)/${EXTRACT_DIR}/${TEST_NAME}"

FAILED_NUM=0

color yellow "Starting test case \"${TEST_NAME}\""

function prepare() {
    mkdir -p "${TEST_OUTPUT_DIR}" "${TEST_EXTRACT_DIR}"
}

function start() {
    docker run --rm \
        --mount "type=bind,source=${TEST_OUTPUT_DIR},target=${REMOTE_DIR}" \
        -e "RCLONE_REMOTE_DIR=${REMOTE_DIR}" \
        -e "ZIP_ENABLE=FALSE" \
        -e "BACKUP_FILE_SUFFIX=test" \
        "${DOCKER_IMAGE}" \
        backup
}

function test() {
    color blue "Testing..."

    ls -l "${TEST_OUTPUT_DIR}"

    docker run --rm \
      --mount "type=bind,source=${TEST_EXTRACT_DIR},target=/bitwarden/data/" \
      --mount "type=bind,source=${TEST_OUTPUT_DIR},target=/bitwarden/restore/" \
      "${DOCKER_IMAGE}" \
      restore \
      -f \
      --db-file "db.test.sqlite3" \
      --config-file "config.test.json" \
      --rsakey-file "rsakey.test.tar" \
      --attachments-file "attachments.test.tar" \
      --sends-file "sends.test.tar"

    check_files_same_in_folders "${DATA_DIR}" "${TEST_EXTRACT_DIR}"
    if [[ $? != 0 ]]; then
        ((FAILED_NUM++))
    fi
}

function cleanup() {
    sudo rm -rf "${TEST_OUTPUT_DIR}" "${TEST_EXTRACT_DIR}"

    unset TEST_OUTPUT_DIR
    unset TEST_EXTRACT_DIR
}

prepare
start
test
cleanup

test_result "${TEST_NAME}" "${FAILED_NUM}"
