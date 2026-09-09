#!/bin/bash

# Unit test for GFS retention policy logic

TEST_NAME="backup-retention-gfs"
FAILED_NUM=0

function color() {
    case $1 in
        red)     echo -e "\033[31m$2\033[0m" ;;
        green)   echo -e "\033[32m$2\033[0m" ;;
        yellow)  echo -e "\033[33m$2\033[0m" ;;
        blue)    echo -e "\033[34m$2\033[0m" ;;
        none)    echo "$2" ;;
    esac
}

if ! declare -f date_format_to_regex > /dev/null; then
    if [[ -f "scripts/includes.sh" ]]; then
        . scripts/includes.sh
    elif [[ -f "/app/includes.sh" ]]; then
        . /app/includes.sh
    fi
fi

# Standalone implementation of GFS evaluation for testing
function evaluate_retention() {
    local -n _remote_files=$1
    local keep_days=$2
    local keep_weeks=$3
    local keep_months=$4
    local keep_years=$5
    local keep_last=$6
    local -n _out_kept=$7
    local -n _out_deleted=$8
    local suffix_pattern="${9:-"%Y%m%d"}"

    _out_kept=()
    _out_deleted=()

    if [[ "${keep_days}" -eq 0 && "${keep_weeks}" -eq 0 && "${keep_months}" -eq 0 && "${keep_years}" -eq 0 && "${keep_last}" -eq 0 ]]; then
        return 0
    fi

    local suffix_rx
    suffix_rx="$(date_format_to_regex "${suffix_pattern}")"

    declare -A SNAPSHOT_TIMESTAMP=()
    declare -A SNAPSHOT_FILES=()
    local SNAPSHOT_IDS=()

    for FILE_ENTRY in "${_remote_files[@]}"; do
        [[ -z "${FILE_ENTRY}" ]] && continue

        local FILE_TS="${FILE_ENTRY%%;*}"
        local FILE_NAME="${FILE_ENTRY#*;}"
        local SNAP_ID=""

        if [[ "${FILE_NAME}" =~ ^backup\.(.+)\.(zip|7z)$ ]]; then
            local SUFFIX="${BASH_REMATCH[1]}"
            if [[ "${SUFFIX}" =~ ^${suffix_rx}$ ]]; then
                SNAP_ID="pkg_${SUFFIX}"
            fi
        elif [[ "${FILE_NAME}" =~ ^db\.(.+)\.(sqlite3|dump|sql)$ ]]; then
            local SUFFIX="${BASH_REMATCH[1]}"
            if [[ "${SUFFIX}" =~ ^${suffix_rx}$ ]]; then
                SNAP_ID="unpacked_${SUFFIX}"
            fi
        elif [[ "${FILE_NAME}" =~ ^config\.(.+)\.json$ ]]; then
            local SUFFIX="${BASH_REMATCH[1]}"
            if [[ "${SUFFIX}" =~ ^${suffix_rx}$ ]]; then
                SNAP_ID="unpacked_${SUFFIX}"
            fi
        elif [[ "${FILE_NAME}" =~ ^(rsakey|attachments|sends)\.(.+)\.tar$ ]]; then
            local SUFFIX="${BASH_REMATCH[2]}"
            if [[ "${SUFFIX}" =~ ^${suffix_rx}$ ]]; then
                SNAP_ID="unpacked_${SUFFIX}"
            fi
        fi

        if [[ -z "${SNAP_ID}" ]]; then
            continue
        fi

        if [[ -z "${SNAPSHOT_TIMESTAMP[${SNAP_ID}]:-}" ]]; then
            SNAPSHOT_TIMESTAMP["${SNAP_ID}"]="${FILE_TS}"
            SNAPSHOT_FILES["${SNAP_ID}"]="${FILE_NAME}"
            SNAPSHOT_IDS+=("${SNAP_ID}")
        else
            SNAPSHOT_FILES["${SNAP_ID}"]="${SNAPSHOT_FILES[${SNAP_ID}]} ${FILE_NAME}"
        fi
    done

    local SORTED_SNAPSHOTS=()
    mapfile -t SORTED_SNAPSHOTS < <(
        for SNAP_ID in "${SNAPSHOT_IDS[@]}"; do
            echo "${SNAPSHOT_TIMESTAMP[${SNAP_ID}]};${SNAP_ID}"
        done | sort -r
    )

    declare -A KEPT_SNAPSHOTS=()
    declare -A SEEN_DAYS=()
    declare -A SEEN_WEEKS=()
    declare -A SEEN_MONTHS=()
    declare -A SEEN_YEARS=()
    local LAST_COUNT=0

    for SNAP_LINE in "${SORTED_SNAPSHOTS[@]}"; do
        [[ -z "${SNAP_LINE}" ]] && continue

        local SNAP_TS="${SNAP_LINE%%;*}"
        local SNAP_ID="${SNAP_LINE#*;}"
        local KEEP_THIS="FALSE"

        if [[ "${keep_last}" -gt 0 && "${LAST_COUNT}" -lt "${keep_last}" ]]; then
            KEEP_THIS="TRUE"
            ((LAST_COUNT++))
        fi

        local DAY_KEY="${SNAP_TS:0:10}"
        local MONTH_KEY="${SNAP_TS:0:7}"
        local YEAR_KEY="${SNAP_TS:0:4}"
        local DATE_INPUT="${SNAP_TS:0:10} ${SNAP_TS:11:8}"
        local WEEK_KEY
        WEEK_KEY=$(date -d "${DATE_INPUT}" +"%G-W%V" 2>/dev/null)
        if [[ -z "${WEEK_KEY}" ]]; then
            WEEK_KEY="${DAY_KEY}"
        fi

        if [[ "${keep_days}" -gt 0 ]]; then
            if [[ -z "${SEEN_DAYS[${DAY_KEY}]:-}" && "${#SEEN_DAYS[@]}" -lt "${keep_days}" ]]; then
                SEEN_DAYS["${DAY_KEY}"]="1"
                KEEP_THIS="TRUE"
            fi
        fi

        if [[ "${keep_weeks}" -gt 0 ]]; then
            if [[ -z "${SEEN_WEEKS[${WEEK_KEY}]:-}" && "${#SEEN_WEEKS[@]}" -lt "${keep_weeks}" ]]; then
                SEEN_WEEKS["${WEEK_KEY}"]="1"
                KEEP_THIS="TRUE"
            fi
        fi

        if [[ "${keep_months}" -gt 0 ]]; then
            if [[ -z "${SEEN_MONTHS[${MONTH_KEY}]:-}" && "${#SEEN_MONTHS[@]}" -lt "${keep_months}" ]]; then
                SEEN_MONTHS["${MONTH_KEY}"]="1"
                KEEP_THIS="TRUE"
            fi
        fi

        if [[ "${keep_years}" -gt 0 ]]; then
            if [[ -z "${SEEN_YEARS[${YEAR_KEY}]:-}" && "${#SEEN_YEARS[@]}" -lt "${keep_years}" ]]; then
                SEEN_YEARS["${YEAR_KEY}"]="1"
                KEEP_THIS="TRUE"
            fi
        fi

        if [[ "${KEEP_THIS}" == "TRUE" ]]; then
            KEPT_SNAPSHOTS["${SNAP_ID}"]="1"
            _out_kept+=("${SNAP_ID}")
        fi
    done

    for SNAP_ID in "${SNAPSHOT_IDS[@]}"; do
        if [[ -z "${KEPT_SNAPSHOTS[${SNAP_ID}]:-}" ]]; then
            for DEL_FILE in ${SNAPSHOT_FILES[${SNAP_ID}]}; do
                _out_deleted+=("${DEL_FILE}")
            done
        fi
    done
}

# Test 1: Disabled retention (all 0)
FILES_TEST1=(
    "2026-08-16T08:00:00Z;backup.20260816.zip"
    "2026-08-15T08:00:00Z;backup.20260815.zip"
)
evaluate_retention FILES_TEST1 0 0 0 0 0 KEPT DELETED
if [[ "${#DELETED[@]}" -ne 0 ]]; then
    color red "Test 1 failed: Expected 0 deleted when retention disabled, got ${#DELETED[@]}"
    ((FAILED_NUM++))
else
    color green "Test 1 (disabled retention) passed"
fi

# Test 2: Daily retention (7 days), older files deleted
FILES_TEST2=()
for i in {0..10}; do
    d=$(date -d "2026-08-16 - $i days" +"%Y-%m-%d")
    tag=$(date -d "2026-08-16 - $i days" +"%Y%m%d")
    FILES_TEST2+=("${d}T08:00:00Z;backup.${tag}.zip")
done
evaluate_retention FILES_TEST2 7 0 0 0 0 KEPT DELETED
if [[ "${#KEPT[@]}" -ne 7 || "${#DELETED[@]}" -ne 4 ]]; then
    color red "Test 2 failed: Expected 7 kept and 4 deleted, got kept=${#KEPT[@]}, deleted=${#DELETED[@]}"
    ((FAILED_NUM++))
else
    color green "Test 2 (daily retention) passed"
fi

# Test 3: GFS defaults (7 days, 4 weeks, 12 months, 3 years) with history spanning 4 years
FILES_TEST3=()
# Generate 4 years of daily backups
for i in {0..1400}; do
    d=$(date -d "2026-08-16 - $i days" +"%Y-%m-%d")
    tag=$(date -d "2026-08-16 - $i days" +"%Y%m%d")
    FILES_TEST3+=("${d}T08:00:00Z;backup.${tag}.zip")
done
evaluate_retention FILES_TEST3 7 4 12 3 0 KEPT DELETED
color blue "Test 3: From 1401 backups, kept=${#KEPT[@]}, deleted=${#DELETED[@]}"
if [[ "${#KEPT[@]}" -lt 15 || "${#KEPT[@]}" -gt 30 || "${#DELETED[@]}" -lt 1370 ]]; then
    color red "Test 3 failed: Unexpected retention count kept=${#KEPT[@]}, deleted=${#DELETED[@]}"
    ((FAILED_NUM++))
else
    color green "Test 3 (GFS full retention) passed"
fi

# Test 4: Unpacked backups (multiple files per snapshot)
FILES_TEST4=(
    "2026-08-16T08:00:00Z;db.20260816.sqlite3"
    "2026-08-16T08:00:00Z;config.20260816.json"
    "2026-08-16T08:00:00Z;rsakey.20260816.tar"
    "2026-08-01T08:00:00Z;db.20260801.sqlite3"
    "2026-08-01T08:00:00Z;config.20260801.json"
    "2026-08-01T08:00:00Z;rsakey.20260801.tar"
    "2026-08-16T08:00:00Z;other_file.txt"
)
evaluate_retention FILES_TEST4 1 0 0 0 0 KEPT DELETED
if [[ "${#KEPT[@]}" -ne 1 || "${#DELETED[@]}" -ne 3 ]]; then
    color red "Test 4 failed: Expected 1 kept snapshot and 3 deleted files, got kept=${#KEPT[@]}, deleted=${#DELETED[@]}"
    ((FAILED_NUM++))
else
    color green "Test 4 (unpacked multi-file snapshots & non-backup file ignore) passed"
fi

# Test 5: Only delete files matching BACKUP_FILE_SUFFIX pattern (%Y%m%d) and valid extensions
FILES_TEST5=(
    "2026-08-16T08:00:00Z;backup.20260816.zip"
    "2026-08-01T08:00:00Z;backup.20260801.zip"
    "2026-08-01T08:00:00Z;backup.other_instance_20260801.zip"
    "2026-08-01T08:00:00Z;backup.my_photos.zip"
    "2026-08-01T08:00:00Z;db.other_inst_20260801.sqlite3"
    "2026-08-01T08:00:00Z;config.20260801.sqlite3"
    "2026-08-01T08:00:00Z;attachments.20260801.zip"
    "2026-08-01T08:00:00Z;rsakey.20260801.dump"
    "2026-08-01T08:00:00Z;sends.20260801.sql"
    "2026-08-01T08:00:00Z;backup.20260801.tar.gz"
)
evaluate_retention FILES_TEST5 1 0 0 0 0 KEPT DELETED "%Y%m%d"
if [[ "${#KEPT[@]}" -ne 1 || "${#DELETED[@]}" -ne 1 || "${DELETED[0]}" != "backup.20260801.zip" ]]; then
    color red "Test 5 failed: Expected only backup.20260801.zip deleted, got deleted=${DELETED[*]}"
    ((FAILED_NUM++))
else
    color green "Test 5 (only delete files matching BACKUP_FILE_SUFFIX pattern) passed"
fi

# Test 6: Custom BACKUP_FILE_SUFFIX pattern (%Y-%m-%d_%H-%M-%S)
FILES_TEST6=(
    "2026-08-16T10:00:00Z;backup.2026-08-16_10-00-00.zip"
    "2026-08-01T10:00:00Z;backup.2026-08-01_10-00-00.zip"
    "2026-08-01T10:00:00Z;backup.20260801.zip"
)
evaluate_retention FILES_TEST6 1 0 0 0 0 KEPT DELETED "%Y-%m-%d_%H-%M-%S"
if [[ "${#KEPT[@]}" -ne 1 || "${#DELETED[@]}" -ne 1 || "${DELETED[0]}" != "backup.2026-08-01_10-00-00.zip" ]]; then
    color red "Test 6 failed: Expected only backup.2026-08-01_10-00-00.zip deleted, got deleted=${DELETED[*]}"
    ((FAILED_NUM++))
else
    color green "Test 6 (custom date format %Y-%m-%d_%H-%M-%S) passed"
fi

# Test 7: Literal BACKUP_FILE_SUFFIX (test)
FILES_TEST7=(
    "2026-08-16T08:00:00Z;backup.test.zip"
    "2026-08-01T08:00:00Z;backup.test1.zip"
    "2026-08-01T08:00:00Z;backup.20260801.zip"
)
evaluate_retention FILES_TEST7 1 0 0 0 0 KEPT DELETED "test"
if [[ "${#KEPT[@]}" -ne 1 || "${#DELETED[@]}" -ne 0 ]]; then
    color red "Test 7 failed: Expected 1 kept and 0 deleted for literal suffix test, got kept=${#KEPT[@]}, deleted=${#DELETED[@]}"
    ((FAILED_NUM++))
else
    color green "Test 7 (literal suffix 'test') passed"
fi

if declare -f test_result > /dev/null; then
    test_result "${TEST_NAME}" "${FAILED_NUM}"
else
    if [[ "${FAILED_NUM}" -eq 0 ]]; then
        color green "All GFS retention unit tests passed"
        exit 0
    else
        color red "${FAILED_NUM} tests failed"
        exit 1
    fi
fi
