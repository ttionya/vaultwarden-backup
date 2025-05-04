#!/bin/bash

TEST_NAME="backup-cron"
TEST_CONTAINER_NAME="${TEST_NAME}"
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
        --name "${TEST_CONTAINER_NAME}" \
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
        docker ps

        if [[ $((TIMER % 20)) -eq 0 ]]; then
            docker logs "${TEST_CONTAINER_NAME}" | tail -10
        fi

        if [[ -f "${BACKUP_FILE}" && -s "${BACKUP_FILE}" ]]; then
            SUCCESS=TRUE
            break
        fi

        sleep 1
        ((TIMER++))
    done

    ls -l "${BACKUP_FILE}"

    if [[ "${SUCCESS}" == "FALSE" ]]; then
        ((FAILED_NUM++))
    fi
}

function cleanup() {
    # stop the container
    docker stop "${TEST_CONTAINER_NAME}"

    rm -rf "${TEST_OUTPUT_DIR}"

    unset TEST_CONTAINER_NAME
    unset TEST_OUTPUT_DIR
    unset PASSWORD
    unset BACKUP_FILE
}

prepare
start
test
cleanup

test_result "${TEST_NAME}" "${FAILED_NUM}"
