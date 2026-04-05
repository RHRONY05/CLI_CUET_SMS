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
    echo "    [2] About"
    echo "    [0] Exit"
    echo ""
    echo "$DIV"
    echo ""
    read -rp "  Choice: " MENU_CHOICE
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
