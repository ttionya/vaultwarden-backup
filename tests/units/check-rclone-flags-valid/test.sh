#!/bin/bash

# Using non-existent flags with Rclone will throw an exception and exit.
#
# This test case ensures the verification method works correctly by triggering the error message.

TEST_NAME="check-rclone-flags-valid"
TEST_OUTPUT_DIR="$(pwd)/${OUTPUT_DIR}/${TEST_NAME}"

PASSWORD="43ef5fec-292d-4f9a-ab97-34f622deb462"

FAILED_NUM=0

color yellow "Starting test case \"${TEST_NAME}\""

function prepare() {
    mkdir -p "${TEST_OUTPUT_DIR}"
}

# function start() {
# }

function test() {
    color blue "Testing..."

    FOUND_MESSAGE_COUNT=$(docker run --rm \
        --mount "type=bind,source=${TEST_OUTPUT_DIR},target=${REMOTE_DIR}" \
        -e "RCLONE_REMOTE_DIR=${REMOTE_DIR}" \
        -e "RCLONE_GLOBAL_FLAG=-v --non-existent" \
        -e "ZIP_PASSWORD=${PASSWORD}" \
        -e "BACKUP_FILE_SUFFIX=test" \
        "${DOCKER_IMAGE}" \
        backup | grep -c "illegal rclone global flags")

    if [[ "${FOUND_MESSAGE_COUNT}" -ne 1 ]]; then
        ((FAILED_NUM++))
    fi
}

function cleanup() {
    sudo rm -rf "${TEST_OUTPUT_DIR}"

    unset TEST_OUTPUT_DIR
    unset PASSWORD
    unset FOUND_MESSAGE_COUNT
}

prepare
# start
test
cleanup

test_result "${TEST_NAME}" "${FAILED_NUM}"
