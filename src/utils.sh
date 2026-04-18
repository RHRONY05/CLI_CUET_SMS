#!/bin/bash
# utils.sh — Shared utility functions and path definitions

_UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$_UTILS_DIR")"

DB_DIR="$BASE_DIR/db"
COURSES_DIR="$BASE_DIR/courses"
LOGS_DIR="$BASE_DIR/logs"
SESSIONS_DIR="$DB_DIR/sessions"

USERS_FILE="$DB_DIR/users.txt"
BATCHES_FILE="$DB_DIR/batches.txt"
COURSES_FILE="$DB_DIR/courses.txt"
ENROLLMENTS_FILE="$DB_DIR/enrollments.txt"
TEACHER_COURSES_FILE="$DB_DIR/teacher_courses.txt"
ACTIVITY_LOG="$LOGS_DIR/activity.log"
REGISTRATIONS_FILE="$DB_DIR/registrations.txt"

# ── Directory bootstrap ───────────────────────────────────────────────────────

init_dirs() {
    mkdir -p "$DB_DIR" "$COURSES_DIR" "$LOGS_DIR" "$SESSIONS_DIR"
    for f in "$USERS_FILE" "$BATCHES_FILE" "$COURSES_FILE" \
              "$ENROLLMENTS_FILE" "$TEACHER_COURSES_FILE" "$ACTIVITY_LOG" \
              "$REGISTRATIONS_FILE"; do
        [ -f "$f" ] || touch "$f"
    done
}

# ── Password hashing ──────────────────────────────────────────────────────────

hash_password() {
    echo -n "$1" | sha256sum | cut -d' ' -f1
}

# ── Logging ───────────────────────────────────────────────────────────────────

log_action() {
    local user="$1" action="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S')|${user}|${action}" >> "$ACTIVITY_LOG"
}

# ── User helpers ──────────────────────────────────────────────────────────────
# users.txt fields: username|fullname|role|password_hash|batch_id|force_pw_change

user_exists() {
    grep -q "^${1}|" "$USERS_FILE" 2>/dev/null
}

get_user_field() {
    # $1=username  $2=field number
    grep "^${1}|" "$USERS_FILE" 2>/dev/null | head -1 | cut -d'|' -f"$2"
}

update_user_field() {
    # $1=username  $2=field number  $3=new value
    local tmp; tmp=$(mktemp)
    awk -F'|' -v u="$1" -v fn="$2" -v nv="$3" 'BEGIN{OFS="|"} {
        if ($1 == u) $fn = nv
        print
    }' "$USERS_FILE" > "$tmp"
    mv "$tmp" "$USERS_FILE"
}

# ── Batch helpers ─────────────────────────────────────────────────────────────
# batches.txt fields: batch_id|year|current_level|current_term|status

batch_exists() {
    grep -q "^${1}|" "$BATCHES_FILE" 2>/dev/null
}

get_batch_field() {
    grep "^${1}|" "$BATCHES_FILE" 2>/dev/null | head -1 | cut -d'|' -f"$2"
}

update_batch_field() {
    local tmp; tmp=$(mktemp)
    awk -F'|' -v bid="$1" -v fn="$2" -v nv="$3" 'BEGIN{OFS="|"} {
        if ($1 == bid) $fn = nv
        print
    }' "$BATCHES_FILE" > "$tmp"
    mv "$tmp" "$BATCHES_FILE"
}

# ── Course helpers ────────────────────────────────────────────────────────────
# courses.txt fields: code|name|credits|level|term|type

course_exists() {
    grep -q "^${1}|" "$COURSES_FILE" 2>/dev/null
}

get_course_field() {
    grep "^${1}|" "$COURSES_FILE" 2>/dev/null | head -1 | cut -d'|' -f"$2"
}

# ── Grade helpers ─────────────────────────────────────────────────────────────
# courses/<code>/grades.txt fields: username|batch_id|grade|gpa_points|timestamp

get_grade_file() {
    echo "$COURSES_DIR/$1/grades.txt"
}

get_notices_file() {
    echo "$COURSES_DIR/$1/notices.txt"
}

ensure_course_dir() {
    mkdir -p "$COURSES_DIR/$1"
    local gf nf
    gf=$(get_grade_file "$1")
    nf=$(get_notices_file "$1")
    [ -f "$gf" ] || touch "$gf"
    [ -f "$nf" ] || touch "$nf"
}

# ── Grade / GPA conversion ────────────────────────────────────────────────────

grade_to_points() {
    case "$1" in
        "A+") echo "4.00" ;;
        "A")  echo "3.75" ;;
        "A-") echo "3.50" ;;
        "B+") echo "3.25" ;;
        "B")  echo "3.00" ;;
        "B-") echo "2.75" ;;
        "C+") echo "2.50" ;;
        "C")  echo "2.25" ;;
        "D")  echo "2.00" ;;
        "F")  echo "0.00" ;;
        *)    echo "" ;;
    esac
}

is_valid_grade() {
    local pts; pts=$(grade_to_points "$1")
    [[ -n "$pts" ]]
}

semester_label() {
    echo "Level-$1 Term-$2"
}

# ── Enrollment helpers ────────────────────────────────────────────────────────
# enrollments.txt fields: username|batch_id|course_code|level|term|status

is_enrolled() {
    # $1=username  $2=course_code
    grep -q "^${1}|[^|]*|${2}|" "$ENROLLMENTS_FILE" 2>/dev/null
}

# ── Misc ──────────────────────────────────────────────────────────────────────

trim() {
    echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

any_admin_exists() {
    grep -q "|admin|" "$USERS_FILE" 2>/dev/null
}
