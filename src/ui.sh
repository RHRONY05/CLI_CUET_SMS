#!/bin/bash
# ui.sh — Shared terminal UI helpers

APP_NAME="CUET CSE Student Management System"
APP_VER="v2.0"
DEPT="Dept. of Computer Science & Engineering"
UNIV="Chittagong University of Engineering & Technology"

SEP="============================================================"
DIV="------------------------------------------------------------"

# ── Basic output ──────────────────────────────────────────────────────────────

print_header() {
    clear
    echo "$SEP"
    printf "  %-56s\n" "$APP_NAME"
    printf "  %-56s\n" "$DEPT"
    printf "  %-56s\n" "$UNIV"
    echo "$SEP"
    echo ""
}

print_section() {
    echo ""
    echo "  [ $1 ]"
    echo "$DIV"
}

print_success() { echo "  [OK]    $1"; }
print_error()   { echo "  [ERROR] $1"; }
print_info()    { echo "  [INFO]  $1"; }
print_warn()    { echo "  [WARN]  $1"; }

pause() {
    echo ""
    read -rp "  Press Enter to continue..."
}

confirm() {
    # Returns 0 for yes, 1 for no
    local answer
    read -rp "  $1 (y/n): " answer
    [[ "$answer" == "y" || "$answer" == "Y" ]]
}

# ── Menu helpers ──────────────────────────────────────────────────────────────

print_menu() {
    # Usage: print_menu "Title" "1:Option One" "2:Option Two" "0:Back"
    local title="$1"; shift
    print_section "$title"
    echo ""
    local item
    for item in "$@"; do
        local num="${item%%:*}"
        local label="${item#*:}"
        printf "    [%s] %s\n" "$num" "$label"
    done
    echo ""
    echo "$DIV"
    echo ""
    read -rp "  Choice: " MENU_CHOICE
    MENU_CHOICE=$(trim "$MENU_CHOICE")
}

# ── Picker helpers (Phase 1) ──────────────────────────────────────────────────

PICKER_KEYS=()
PICKER_LABELS=()
PICKED_ID=""

clear_picker() {
    PICKER_KEYS=()
    PICKER_LABELS=()
    PICKED_ID=""
}

_render_picker() {
    local title="$1"
    if [[ ${#PICKER_KEYS[@]} -eq 0 ]]; then
        print_error "No options available."
        PICKED_ID=""
        return 1
    fi
    echo ""
    echo "  $title"
    echo "$DIV"
    for i in "${!PICKER_KEYS[@]}"; do
        printf "    [%d] %s\n" "$((i+1))" "${PICKER_LABELS[$i]}"
    done
    echo "    [0] Cancel"
    echo "$DIV"
    echo ""
    
    local choice
    while true; do
        read -rp "  Choice: " choice
        choice=$(trim "$choice")
        if [[ "$choice" == "0" ]]; then
            PICKED_ID=""
            return 1
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#PICKER_KEYS[@]}" ]; then
            PICKED_ID="${PICKER_KEYS[$((choice-1))]}"
            return 0
        fi
        print_error "Invalid choice."
    done
}

pick_batch() {
    clear_picker
    while IFS='|' read -r bid year level term status; do
        [[ -z "$bid" ]] && continue
        PICKER_KEYS+=("$bid")
        PICKER_LABELS+=("$bid (Level-$level Term-$term, $status)")
    done < "$BATCHES_FILE"
    _render_picker "Select Batch"
}

pick_user() {
    local role_filter="$1"
    clear_picker
    while IFS='|' read -r uname fullname role _ batch _; do
        [[ -z "$uname" ]] && continue
        if [[ -z "$role_filter" || "$role" == "$role_filter" ]]; then
            PICKER_KEYS+=("$uname")
            if [[ "$role" == "student" && -n "$batch" ]]; then
                PICKER_LABELS+=("$uname - $fullname ($role, $batch)")
            else
                PICKER_LABELS+=("$uname - $fullname ($role)")
            fi
        fi
    done < "$USERS_FILE"
    _render_picker "Select User"
}

pick_course() {
    clear_picker
    while IFS='|' read -r code name creds lvl term type; do
        [[ -z "$code" ]] && continue
        PICKER_KEYS+=("$code")
        PICKER_LABELS+=("[$code] $name")
    done < "$COURSES_FILE"
    _render_picker "Select Course"
}

# ── Table helpers ─────────────────────────────────────────────────────────────

print_table_header() {
    echo ""
    printf "$@"
    echo ""
    echo "$DIV"
}

# ── Landing page ──────────────────────────────────────────────────────────────

print_landing() {
    print_header
    echo "  Welcome to the CUET CSE Student Management System"
    echo ""
    echo "  Manage academic records for the CSE Department across"
    echo "  all semesters — grades, notices, and CGPA tracking."
    echo ""
    echo "  Roles:"
    echo "    Admin   —  Manage users, batches, courses, enrollment"
    echo "    Teacher —  Enter grades, post notices"
    echo "    Student —  View grades, CGPA, notices"
    echo ""
    echo "$DIV"
    echo ""
    echo "    [1] Login"
    echo "    [2] Register (Student)"
    echo "    [3] About"
    echo "    [0] Exit"
    echo ""
    echo "$DIV"
    echo ""
    read -rp "  Choice: " MENU_CHOICE
    MENU_CHOICE=$(trim "$MENU_CHOICE")
}

print_about() {
    print_header
    print_section "About"
    echo ""
    echo "  $APP_NAME  $APP_VER"
    echo ""
    echo "  Developed for CSE 336 — Operating Systems Sessional"
    echo "  $UNIV"
    echo ""
    echo "  Features:"
    echo "    - File-based authentication (SHA-256 hashed passwords)"
    echo "    - Role-based access control (Admin / Teacher / Student)"
    echo "    - Multi-semester grade tracking (8 semesters)"
    echo "    - Automatic CGPA calculation"
    echo "    - Course notice board"
    echo "    - Full activity logging"
    echo ""
    pause
}
