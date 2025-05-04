#!/bin/bash

TEST_NAME="env-priority"
TEST_OUTPUT_DIR="$(pwd)/${OUTPUT_DIR}/${TEST_NAME}"
TEST_TEMP_DIR="$(pwd)/${TEMP_DIR}/${TEST_NAME}"

PASSWORD1="32aeec18-3bce-43af-b41d-7be04b0f7810" # For 1
PASSWORD2="ce3cbc42-186b-4d1b-a1a9-3f10f0ec59c7" # For 2
PASSWORD3="0e0fdbc1-5b2f-44db-ac7d-f0a8764992a7" # For 3
PASSWORD4="0ddd9b27-ca9b-4912-b6fb-76569ec5cac1" # For 4
PASSWORD2_FILE="${TEST_TEMP_DIR}/password2"
PASSWORD3_FILE="${TEST_TEMP_DIR}/password3"
BACKUP_FILE1="${TEST_OUTPUT_DIR}/backup.test1.zip"
BACKUP_FILE2="${TEST_OUTPUT_DIR}/backup.test2.zip"
BACKUP_FILE3="${TEST_OUTPUT_DIR}/backup.test3.zip"
BACKUP_FILE4="${TEST_OUTPUT_DIR}/backup.test4.zip"
ENV_FILE1="${TEST_TEMP_DIR}/.env1"
ENV_FILE4="${TEST_TEMP_DIR}/.env4"

FAILED_NUM=0

color yellow "Starting test case \"${TEST_NAME}\""

function prepare() {
    mkdir -p "${TEST_OUTPUT_DIR}" "${TEST_TEMP_DIR}"

    echo "${PASSWORD2}" > "${PASSWORD2_FILE}"
    echo "${PASSWORD3}" > "${PASSWORD3_FILE}"

    cat > "${ENV_FILE1}" << EOF
ZIP_PASSWORD_FILE="/password3"
ZIP_PASSWORD="${PASSWORD4}"
EOF
    cat > "${ENV_FILE4}" << EOF
ZIP_PASSWORD="${PASSWORD4}"
EOF
}

function start() {
    docker run --rm \
        --mount "type=bind,source=${TEST_OUTPUT_DIR},target=${REMOTE_DIR}" \
        --mount "type=bind,source=${PASSWORD2_FILE},target=/password2" \
        --mount "type=bind,source=${PASSWORD3_FILE},target=/password3" \
        --mount "type=bind,source=${ENV_FILE1},target=/.env" \
        -e "RCLONE_REMOTE_DIR=${REMOTE_DIR}" \
        -e "ZIP_PASSWORD=${PASSWORD1}" \
        -e "ZIP_PASSWORD_FILE=/password2" \
        -e "BACKUP_FILE_SUFFIX=test1" \
        "${DOCKER_IMAGE}" \
        backup

    docker run --rm \
        --mount "type=bind,source=${TEST_OUTPUT_DIR},target=${REMOTE_DIR}" \
        --mount "type=bind,source=${PASSWORD2_FILE},target=/password2" \
        --mount "type=bind,source=${PASSWORD3_FILE},target=/password3" \
        --mount "type=bind,source=${ENV_FILE1},target=/.env" \
        -e "RCLONE_REMOTE_DIR=${REMOTE_DIR}" \
        -e "ZIP_PASSWORD_FILE=/password2" \
        -e "BACKUP_FILE_SUFFIX=test2" \
        "${DOCKER_IMAGE}" \
        backup

    docker run --rm \
        --mount "type=bind,source=${TEST_OUTPUT_DIR},target=${REMOTE_DIR}" \
        --mount "type=bind,source=${PASSWORD2_FILE},target=/password2" \
        --mount "type=bind,source=${PASSWORD3_FILE},target=/password3" \
        --mount "type=bind,source=${ENV_FILE1},target=/.env" \
        -e "RCLONE_REMOTE_DIR=${REMOTE_DIR}" \
        -e "BACKUP_FILE_SUFFIX=test3" \
        "${DOCKER_IMAGE}" \
        backup

    docker run --rm \
        --mount "type=bind,source=${TEST_OUTPUT_DIR},target=${REMOTE_DIR}" \
        --mount "type=bind,source=${PASSWORD2_FILE},target=/password2" \
        --mount "type=bind,source=${PASSWORD3_FILE},target=/password3" \
        --mount "type=bind,source=${ENV_FILE4},target=/.env" \
        -e "RCLONE_REMOTE_DIR=${REMOTE_DIR}" \
        -e "BACKUP_FILE_SUFFIX=test4" \
        "${DOCKER_IMAGE}" \
        backup
}

function test() {
    color blue "Testing..."

    ls -l "${TEST_OUTPUT_DIR}"

    7z l -p"${PASSWORD1}" "${BACKUP_FILE1}"
    if [[ $? != 0 ]]; then
        ((FAILED_NUM++))
    fi

    7z l -p"${PASSWORD2}" "${BACKUP_FILE2}"
    if [[ $? != 0 ]]; then
        ((FAILED_NUM++))
    fi

    7z l -p"${PASSWORD3}" "${BACKUP_FILE3}"
    if [[ $? != 0 ]]; then
        ((FAILED_NUM++))
    fi

    7z l -p"${PASSWORD4}" "${BACKUP_FILE4}"
    if [[ $? != 0 ]]; then
        ((FAILED_NUM++))
    fi
}

function cleanup() {
    sudo rm -rf "${TEST_OUTPUT_DIR}" "${TEST_TEMP_DIR}"

    unset TEST_OUTPUT_DIR
    unset TEST_TEMP_DIR
    unset PASSWORD1
    unset PASSWORD2
    unset PASSWORD3
    unset PASSWORD4
    unset PASSWORD2_FILE
    unset PASSWORD3_FILE
    unset BACKUP_FILE1
    unset BACKUP_FILE2
    unset BACKUP_FILE3
    unset BACKUP_FILE4
    unset ENV_FILE1
    unset ENV_FILE4
}

prepare
start
test
cleanup

test_result "${TEST_NAME}" "${FAILED_NUM}"
