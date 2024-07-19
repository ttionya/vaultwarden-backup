#!/bin/bash


DOCKER_IMAGE="ttionya/vaultwarden-backup:test"
ERROR_NUM=0

DATA_DIR="$(pwd)/tests/fixtures/source/bitwarden/data"
OUTPUT_DIR="output"
EXTRACT_DIR="extract"
REMOTE_DIR="/${OUTPUT_DIR}"

########################################
# Print colorful message.
# Arguments:
#     color
#     message
# Outputs:
#     colorful message
########################################
function color() {
    case $1 in
        red)     echo -e "\033[31m$2\033[0m" ;;
        green)   echo -e "\033[32m$2\033[0m" ;;
        yellow)  echo -e "\033[33m$2\033[0m" ;;
        blue)    echo -e "\033[34m$2\033[0m" ;;
        none)    echo "$2" ;;
    esac
}

########################################
# Check if the files in two folders are the same.
# Arguments:
#     folder1
#     folder2
# Outputs:
#     progress
# Returns:
#     same or not
########################################
function check_files_same_in_folders() {
    function generate_hash_list() {
        find "$1" -type f -not -name "db.*" -exec sha1sum {} \; | sort | sed "s|$1||g" > "$2"
    }

    color blue "Calculating file hash in folder \"$1\" and \"$2\""

    local FOLDER1="$1"
    local FOLDER2="$2"
    local FOLDER1_HASH_LIST="/tmp/folder1_hash_list"
    local FOLDER2_HASH_LIST="/tmp/folder2_hash_list"
    generate_hash_list "${FOLDER1}" "${FOLDER1_HASH_LIST}"
    generate_hash_list "${FOLDER2}" "${FOLDER2_HASH_LIST}"

    color blue "Calculating differences"

    local RETURN_CODE
    local FOLDER_HASH_DIFF="/tmp/folder_hash_diff"
    if diff "${FOLDER1_HASH_LIST}" "${FOLDER2_HASH_LIST}" > "${FOLDER_HASH_DIFF}"; then
        RETURN_CODE=0
    else
        RETURN_CODE=1
        cat "${FOLDER_HASH_DIFF}"
    fi

    rm -rf "${FOLDER1_HASH_LIST}" "${FOLDER2_HASH_LIST}" "${FOLDER_HASH_DIFF}"

    return "${RETURN_CODE}"
}

########################################
# Show test result.
# Arguments:
#     test name
#     failed number
# Outputs:
#     test result
########################################
function test_result() {
    if [[ "$2" == "0" ]]; then
        color green "Test case \"$1\" passed"
        return
    fi

    ((ERROR_NUM++))

    color red "Test case \"$1\" failed"
}

. tests/units/backup-zip-file/test.sh
. tests/units/backup-7z-file/test.sh

if [[ "${ERROR_NUM}" == "0" ]]; then
    color green "All tests passed"
else
    color red "Some tests failed"
    exit 1
fi
