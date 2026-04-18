#!/bin/bash
# main.sh — CUET CSE Student Management System
# Usage: bash main.sh
# Usage (with demo data): bash main.sh --demo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/src/utils.sh"
source "$SCRIPT_DIR/src/ui.sh"
source "$SCRIPT_DIR/src/auth.sh"
source "$SCRIPT_DIR/src/admin_panel.sh"
source "$SCRIPT_DIR/src/teacher_panel.sh"
source "$SCRIPT_DIR/src/student_panel.sh"

# ── Bootstrap ─────────────────────────────────────────────────────────────────

init_dirs

# Load demo data if requested
if [[ "$1" == "--demo" ]]; then
    echo "  Loading demo data..."
    bash "$SCRIPT_DIR/setup/demo_data.sh"
    echo ""
    read -rp "  Press Enter to continue to login..."
fi

# First-run: no admin exists → run setup wizard
if ! any_admin_exists; then
    first_run_setup
fi

# ── Main loop ─────────────────────────────────────────────────────────────────

while true; do
    print_landing

    case "$MENU_CHOICE" in
        1)
            if do_login; then
                case "$SESSION_ROLE" in
                    admin)   admin_panel ;;
                    teacher) teacher_panel ;;
                    student) student_panel ;;
                    *)
                        print_error "Unknown role: $SESSION_ROLE"
                        do_logout
                        pause
                        ;;
                esac
            fi
            ;;
        2)
            student_registration
            ;;
        3)
            print_about
            ;;
        0)
            echo ""
            echo "  Goodbye!"
            echo ""
            exit 0
            ;;
        *)
            print_error "Invalid choice."
            pause
            ;;
    esac
done
