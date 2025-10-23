#!/bin/bash

# During Rclone connection verification, the configuration is considered complete
# by checking for the presence of `RCLONE_REMOTE_NAME` in the configuration file.
#
# This test case ensures the verification method works by triggering the expected error message.

TEST_NAME="check-rclone-config-exits"
TEST_OUTPUT_DIR="$(pwd)/${OUTPUT_DIR}/${TEST_NAME}"
TEST_CONFIG_DIR="$(pwd)/${CONFIG_DIR}/${TEST_NAME}"

PASSWORD="231454f1-594c-45e2-8810-3ac917ebcf70"

FAILED_NUM=0

color yellow "Starting test case \"${TEST_NAME}\""

function prepare() {
    mkdir -p "${TEST_OUTPUT_DIR}" "${TEST_CONFIG_DIR}"
}

function start() {
    echo ""
}

function test() {
    color blue "Testing..."

    FOUND_MESSAGE_COUNT=$(docker run --rm \
        --mount "type=bind,source=${TEST_OUTPUT_DIR},target=${REMOTE_DIR}" \
        --mount "type=bind,source=${TEST_RCLONE_CONFIG_DIR},target=/config" \
        -e "RCLONE_REMOTE_DIR=${REMOTE_DIR}" \
        -e "ZIP_PASSWORD=${PASSWORD}" \
        -e "BACKUP_FILE_SUFFIX=test" \
        "${DOCKER_IMAGE}" \
        backup | grep -c "rclone configuration information not found")

    if [[ "${FOUND_MESSAGE_COUNT}" -ne 1 ]]; then
        ((FAILED_NUM++))
    fi
}

function cleanup() {
    sudo rm -rf "${TEST_OUTPUT_DIR}" "${TEST_CONFIG_DIR}"

    unset TEST_OUTPUT_DIR
    unset TEST_CONFIG_DIR
    unset PASSWORD
    unset FOUND_MESSAGE_COUNT
}

prepare
start
test
cleanup

test_result "${TEST_NAME}" "${FAILED_NUM}"
