#!/bin/bash


DOCKER_IMAGE="ttionya/vaultwarden-backup:test"
ERROR_NUM=0

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

. tests/units/backup-zip-file/test.sh

if [[ "${ERROR_NUM}" == "0" ]]; then
    color green "All tests passed."
else
    color red "Some tests failed."
    exit 1
fi
