#!/bin/bash

TEST_NAME="backup-cron"
TEST_OUTPUT_DIR="$(pwd)/${OUTPUT_DIR}/${TEST_NAME}"

PASSWORD="faedea12-7f9e-4d84-983f-d049d9b82a36"
BACKUP_FILE="${TEST_OUTPUT_DIR}/backup.test.zip"

FAILED_NUM=0

color yellow "Starting test case \"${TEST_NAME}\""

function prepare() {
    mkdir -p "${TEST_OUTPUT_DIR}"
}

function start() {
    docker run --rm -d \
        --name "${TEST_NAME}" \
        --mount "type=bind,source=${TEST_OUTPUT_DIR},target=${REMOTE_DIR}" \
        -e "RCLONE_REMOTE_DIR=${REMOTE_DIR}" \
        -e "ZIP_PASSWORD=${PASSWORD}" \
        -e "BACKUP_FILE_SUFFIX=test" \
        -e "CRON='* * * * *'" \
        "${DOCKER_IMAGE}"
}

function test() {
    color blue "Testing..."

    local TIMER=0
    local SUCCESS=FALSE

    # wait 120s
    while [[ "${TIMER}" -lt 120 ]]; do
        if [[ -f "${BACKUP_FILE}" && -s "${BACKUP_FILE}" ]]; then
            SUCCESS=TRUE
            break
        fi

        sleep 1
        ((TIMER++))
    done

    # stop the container
    docker stop "${TEST_NAME}"

    ls -l "${BACKUP_FILE}"

    if [[ "${SUCCESS}" == "FALSE" ]]; then
        ((FAILED_NUM++))
    fi
}

prepare
start
test

test_result "${TEST_NAME}" "${FAILED_NUM}"
