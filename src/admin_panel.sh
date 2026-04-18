#!/bin/bash
# admin_panel.sh — Admin dashboard

admin_panel() {
    while true; do
        print_header
        echo "  🛡️   Logged in as: $SESSION_FULLNAME (Admin)"
        print_menu "Admin Panel" \
            "1:👥  User Management" \
            "2:🎓  Batch Management" \
            "3:📚  Course and Teacher Assignment" \
            "4:📋  Enrollment Management" \
            "5:📊  Reports" \
            "6:📜  Activity Log" \
            "0:🚪  Logout"

        case "$MENU_CHOICE" in
            1) _admin_user_management ;;
            2) _admin_batch_management ;;
            3) _admin_course_management ;;
            4) _admin_enrollment_management ;;
            5) _admin_reports ;;
            6) _admin_view_log ;;
            0) do_logout; return ;;
            *) print_error "Invalid choice."; pause ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# USER MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

_admin_user_management() {
    while true; do
        print_header
        print_menu "User Management" \
            "1:➕  Add Student" \
            "2:➕  Add Teacher" \
            "3:➕  Add Admin" \
            "4:📋  List All Users" \
            "5:🗑️   Delete User" \
            "6:🔑  Reset User Password" \
            "7:⏳  Pending Registrations" \
            "0:◀️   Back"

        case "$MENU_CHOICE" in
            1) _add_user_flow "student" ;;
            2) _add_user_flow "teacher" ;;
            3) _add_user_flow "admin" ;;
            4) _list_users ;;
            5) _delete_user ;;
            6) _reset_password ;;
            7) _pending_registrations ;;
            0) return ;;
            *) print_error "Invalid choice."; pause ;;
        esac
    done
}

_add_user_flow() {
    local role="$1"
    print_header
    print_section "Add $role"
    echo ""

    local uname
    while true; do
        read -rp "  Username   : " uname
        uname=$(trim "$uname")
        if [[ -z "$uname" ]]; then print_error "Username cannot be empty."; continue; fi
        if [[ ! "$uname" =~ ^[a-zA-Z0-9_]+$ ]]; then
            print_error "Only letters, numbers, underscores allowed."; continue
        fi
        if user_exists "$uname"; then print_error "Username '$uname' already exists."; continue; fi
        break
    done

    local fullname
    while true; do
        read -rp "  Full Name  : " fullname
        fullname=$(trim "$fullname")
        [[ -n "$fullname" ]] && break
        print_error "Full name cannot be empty."
    done

    local batch_id=""
    if [[ "$role" == "student" ]]; then
        if ! pick_batch; then return; fi
        batch_id="$PICKED_ID"
    fi

    local tmp_pass
    while true; do
        read -rsp "  Temp Password : " tmp_pass; echo ""
        if [[ ${#tmp_pass} -lt 6 ]]; then
            print_error "Password must be at least 6 characters."; continue
        fi
        break
    done

    local hash; hash=$(hash_password "$tmp_pass")
    echo "${uname}|${fullname}|${role}|${hash}|${batch_id}|1" >> "$USERS_FILE"

    log_action "$SESSION_USERNAME" "ADD_USER:${uname}:${role}"
    echo ""
    print_success "User '$uname' created."
    echo ""
    echo "  Share these credentials:"
    echo "    Username : $uname"
    echo "    Password : $tmp_pass  (user must change on first login)"
    pause
}

_list_users() {
    print_header
    print_section "All Users"
    printf "\n  %-15s %-28s %-10s %-12s\n" "Username" "Full Name" "Role" "Batch"
    echo "$DIV"
    while IFS='|' read -r uname fullname role _ batch _; do
        printf "  %-15s %-28s %-10s %-12s\n" "$uname" "$fullname" "$role" "${batch:--}"
    done < "$USERS_FILE"
    pause
}

_delete_user() {
    print_header
    if ! pick_user; then return; fi
    local uname="$PICKED_ID"

    if [[ "$uname" == "$SESSION_USERNAME" ]]; then
        print_error "You cannot delete your own account."; pause; return
    fi

    local fullname role
    fullname=$(get_user_field "$uname" 2)
    role=$(get_user_field "$uname" 3)
    echo "  User : $uname | $fullname | $role"
    echo ""

    if ! confirm "Delete this user?"; then
        print_info "Cancelled."; pause; return
    fi

    local tmp; tmp=$(mktemp)
    grep -v "^${uname}|" "$USERS_FILE" > "$tmp"
    mv "$tmp" "$USERS_FILE"

    log_action "$SESSION_USERNAME" "DELETE_USER:${uname}"
    print_success "User '$uname' deleted."
    pause
}

_pending_registrations() {
    while true; do
        print_header
        
        local count=0
        if [[ -f "$REGISTRATIONS_FILE" ]]; then
            count=$(grep -c "|pending|" "$REGISTRATIONS_FILE" || echo 0)
        fi
        
        if (( count == 0 )); then
            print_section "Pending Registrations"
            echo ""
            print_success "No pending registrations to process."
            pause
            return
        fi

        clear_picker
        while IFS='|' read -r uname fullname hash bid trx status ts; do
            if [[ "$status" == "pending" ]]; then
                PICKER_KEYS+=("$uname")
                PICKER_LABELS+=("$uname - $fullname ($bid) — TRX: $trx")
            fi
        done < "$REGISTRATIONS_FILE"

        if ! _render_picker "Pending Registrations to Process"; then
            return
        fi

        _process_single_registration "$PICKED_ID"
    done
}

_process_single_registration() {
    local t_uname="$1"
    
    local line
    line=$(grep "^${t_uname}|" "$REGISTRATIONS_FILE")
    local t_full t_hash t_bid t_trx t_status t_ts
    
    t_full=$(echo "$line" | cut -d'|' -f2)
    t_hash=$(echo "$line" | cut -d'|' -f3)
    t_bid=$(echo "$line"  | cut -d'|' -f4)
    t_trx=$(echo "$line"  | cut -d'|' -f5)
    t_ts=$(echo "$line"   | cut -d'|' -f7)

    print_header
    print_section "Process Registration"
    echo ""
    echo "  Username  : $t_uname"
    echo "  Full Name : $t_full"
    echo "  Batch     : $t_bid"
    echo "  Payment ID: $t_trx"
    echo "  Amount    : 500 BDT"
    echo "  Submitted : $t_ts"
    echo ""
    
    print_menu "Action" \
        "1:✅  Approve" \
        "2:❌  Reject" \
        "0:◀️   Cancel"

    case "$MENU_CHOICE" in
        1)
            echo "${t_uname}|${t_full}|student|${t_hash}|${t_bid}|0" >> "$USERS_FILE"
            
            local tmp; tmp=$(mktemp)
            awk -F'|' -v u="$t_uname" 'BEGIN{OFS="|"} {
                if ($1 == u && $6 == "pending") { $6 = "approved" }
                print
            }' "$REGISTRATIONS_FILE" > "$tmp"
            mv "$tmp" "$REGISTRATIONS_FILE"
            
            log_action "$SESSION_USERNAME" "APPROVE_REGISTRATION:${t_uname}"
            print_success "Registration for '$t_uname' APPROVED."
            pause
            ;;
        2)
            local tmp; tmp=$(mktemp)
            awk -F'|' -v u="$t_uname" 'BEGIN{OFS="|"} {
                if ($1 == u && $6 == "pending") { $6 = "rejected" }
                print
            }' "$REGISTRATIONS_FILE" > "$tmp"
            mv "$tmp" "$REGISTRATIONS_FILE"
            
            log_action "$SESSION_USERNAME" "REJECT_REGISTRATION:${t_uname}"
            print_success "Registration for '$t_uname' REJECTED."
            pause
            ;;
        *)
            return
            ;;
    esac
}

_reset_password() {
    print_header
    if ! pick_user; then return; fi
    local uname="$PICKED_ID"

    local new_pass
    while true; do
        read -rsp "  New Password: " new_pass; echo ""
        if [[ ${#new_pass} -lt 6 ]]; then
            print_error "Password must be at least 6 characters."; continue
        fi
        break
    done

    local hash; hash=$(hash_password "$new_pass")
    local tmp; tmp=$(mktemp)
    awk -F'|' -v u="$uname" -v nh="$hash" 'BEGIN{OFS="|"} {
        if ($1 == u) { $4 = nh; $6 = "1" }
        print
    }' "$USERS_FILE" > "$tmp"
    mv "$tmp" "$USERS_FILE"

    log_action "$SESSION_USERNAME" "RESET_PASSWORD:${uname}"
    print_success "Password reset for '$uname'. They must change it on next login."
    pause
}

# ══════════════════════════════════════════════════════════════════════════════
# BATCH MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

_admin_batch_management() {
    while true; do
        print_header
        print_menu "Batch Management" \
            "1:➕  Create New Batch" \
            "2:⏭️   Advance Batch to Next Semester" \
            "3:📋  List All Batches" \
            "4:👥  View Students in Batch" \
            "0:◀️   Back"

        case "$MENU_CHOICE" in
            1) _create_batch ;;
            2) _advance_batch ;;
            3) _list_batches ;;
            4) _view_batch_students ;;
            0) return ;;
            *) print_error "Invalid choice."; pause ;;
        esac
    done
}

_create_batch() {
    print_header
    print_section "Create New Batch"
    echo ""

    local bid year
    while true; do
        read -rp "  Batch ID (e.g. CSE2025): " bid
        bid=$(trim "$bid")
        if [[ -z "$bid" ]]; then print_error "Batch ID cannot be empty."; continue; fi
        if batch_exists "$bid"; then print_error "Batch '$bid' already exists."; continue; fi
        break
    done

    while true; do
        read -rp "  Admission Year   : " year
        year=$(trim "$year")
        [[ "$year" =~ ^[0-9]{4}$ ]] && break
        print_error "Enter a valid 4-digit year."
    done

    echo "${bid}|${year}|1|1|active" >> "$BATCHES_FILE"
    log_action "$SESSION_USERNAME" "CREATE_BATCH:${bid}"
    print_success "Batch '$bid' created (Level-1 Term-1, active)."
    echo "  Next: use Enrollment Management to enroll this batch."
    pause
}

_advance_batch() {
    print_header
    if ! pick_batch; then return; fi
    local bid="$PICKED_ID"

    local cur_level cur_term status
    cur_level=$(get_batch_field "$bid" 3)
    cur_term=$(get_batch_field  "$bid" 4)
    status=$(get_batch_field    "$bid" 5)

    if [[ "$status" == "completed" ]]; then
        print_error "Batch '$bid' is already completed (graduated)."; pause; return
    fi

    if [[ "$cur_level" == "4" && "$cur_term" == "2" ]]; then
        echo "  This batch is in the final semester."
        if confirm "Mark batch as completed (graduated)?"; then
            update_batch_field "$bid" 5 "completed"
            # Lock all remaining active enrollments
            local tmp; tmp=$(mktemp)
            awk -F'|' -v bid="$bid" 'BEGIN{OFS="|"} {
                if ($2==bid && $6=="active") $6="completed"
                print
            }' "$ENROLLMENTS_FILE" > "$tmp"
            mv "$tmp" "$ENROLLMENTS_FILE"
            log_action "$SESSION_USERNAME" "BATCH_GRADUATED:${bid}"
            print_success "Batch '$bid' marked as graduated."
        fi
        pause; return
    fi

    local new_level="$cur_level" new_term
    if [[ "$cur_term" == "1" ]]; then
        new_term=2
    else
        new_term=1
        new_level=$((cur_level + 1))
    fi

    echo "  Current : Level-${cur_level} Term-${cur_term}"
    echo "  New     : Level-${new_level} Term-${new_term}"
    echo ""

    if ! confirm "Advance batch '$bid'?"; then
        print_info "Cancelled."; pause; return
    fi

    # Lock current active enrollments
    local tmp; tmp=$(mktemp)
    awk -F'|' -v bid="$bid" 'BEGIN{OFS="|"} {
        if ($2==bid && $6=="active") $6="completed"
        print
    }' "$ENROLLMENTS_FILE" > "$tmp"
    mv "$tmp" "$ENROLLMENTS_FILE"

    update_batch_field "$bid" 3 "$new_level"
    update_batch_field "$bid" 4 "$new_term"

    log_action "$SESSION_USERNAME" "ADVANCE_BATCH:${bid}:L${new_level}T${new_term}"
    print_success "Batch '$bid' advanced to Level-${new_level} Term-${new_term}."
    echo "  Previous semester enrollments are now locked."
    echo "  Use Enrollment Management to enroll for the new semester."
    pause
}

_list_batches() {
    print_header
    print_section "All Batches"
    printf "\n  %-12s %-6s %-20s %-10s\n" "Batch ID" "Year" "Current Semester" "Status"
    echo "$DIV"
    _list_batches_inline
    pause
}

_list_batches_inline() {
    while IFS='|' read -r bid year level term status; do
        printf "  %-12s %-6s %-20s %-10s\n" \
            "$bid" "$year" "Level-${level} Term-${term}" "$status"
    done < "$BATCHES_FILE"
}

_view_batch_students() {
    print_header
    if ! pick_batch; then return; fi
    local bid="$PICKED_ID"

    local level term
    level=$(get_batch_field "$bid" 3)
    term=$(get_batch_field  "$bid" 4)

    echo ""
    echo "  Batch: $bid  |  Level-${level} Term-${term}"
    printf "\n  %-15s %-28s\n" "Username" "Full Name"
    echo "$DIV"

    local count=0
    while IFS='|' read -r uname fullname role _ batch _; do
        if [[ "$role" == "student" && "$batch" == "$bid" ]]; then
            printf "  %-15s %-28s\n" "$uname" "$fullname"
            ((count++))
        fi
    done < "$USERS_FILE"

    echo ""
    echo "  Total: $count student(s)"
    pause
}

# ══════════════════════════════════════════════════════════════════════════════
# COURSE AND TEACHER ASSIGNMENT
# ══════════════════════════════════════════════════════════════════════════════

_admin_course_management() {
    while true; do
        print_header
        print_menu "Course and Teacher Assignment" \
            "1:📖  View Curriculum (all semesters)" \
            "2:👨‍🏫  Assign Teacher to Course" \
            "3:❌  Remove Teacher from Course" \
            "4:📋  View All Teacher Assignments" \
            "0:◀️   Back"

        case "$MENU_CHOICE" in
            1) _view_curriculum ;;
            2) _assign_teacher ;;
            3) _remove_teacher_assignment ;;
            4) _view_teacher_assignments ;;
            0) return ;;
            *) print_error "Invalid choice."; pause ;;
        esac
    done
}

_view_curriculum() {
    print_header
    print_section "CUET CSE Curriculum — All 8 Semesters"

    local cur_sem=""
    while IFS='|' read -r code name credits level term type; do
        local sem="Level-${level} Term-${term}"
        if [[ "$sem" != "$cur_sem" ]]; then
            echo ""
            echo "  ── $sem ──"
            printf "  %-10s %-40s %-8s %s\n" "Code" "Course Name" "Credits" "Type"
            echo "$DIV"
            cur_sem="$sem"
        fi
        printf "  %-10s %-40s %-8s %s\n" "$code" "$name" "$credits" "$type"
    done < "$COURSES_FILE"

    pause
}

_assign_teacher() {
    print_header
    if ! pick_user "teacher"; then return; fi
    local teacher="$PICKED_ID"

    if ! pick_course; then return; fi
    local code="$PICKED_ID"

    if grep -q "^${teacher}|${code}$" "$TEACHER_COURSES_FILE"; then
        print_warn "Assignment already exists."; pause; return
    fi

    echo "${teacher}|${code}" >> "$TEACHER_COURSES_FILE"
    log_action "$SESSION_USERNAME" "ASSIGN_TEACHER:${teacher}:${code}"

    local cname; cname=$(get_course_field "$code" 2)
    print_success "Assigned '$teacher' to [$code] $cname"
    pause
}

_remove_teacher_assignment() {
    print_header
    if ! pick_user "teacher"; then return; fi
    local teacher="$PICKED_ID"

    clear_picker
    while IFS='|' read -r t code; do
        if [[ "$t" == "$teacher" ]]; then
            local cname; cname=$(get_course_field "$code" 2)
            PICKER_KEYS+=("$code")
            PICKER_LABELS+=("[$code] $cname")
        fi
    done < "$TEACHER_COURSES_FILE"
    
    if ! _render_picker "Select Course to Remove"; then return; fi
    local code="$PICKED_ID"

    if ! grep -q "^${teacher}|${code}$" "$TEACHER_COURSES_FILE"; then
        print_error "Assignment not found."; pause; return
    fi

    local tmp; tmp=$(mktemp)
    grep -v "^${teacher}|${code}$" "$TEACHER_COURSES_FILE" > "$tmp"
    mv "$tmp" "$TEACHER_COURSES_FILE"

    log_action "$SESSION_USERNAME" "REMOVE_TEACHER_ASSIGNMENT:${teacher}:${code}"
    print_success "Assignment removed."
    pause
}

_view_teacher_assignments() {
    print_header
    print_section "Teacher Course Assignments"
    printf "\n  %-18s %-10s %-35s\n" "Teacher" "Code" "Course Name"
    echo "$DIV"

    while IFS='|' read -r teacher code; do
        local cname; cname=$(get_course_field "$code" 2)
        printf "  %-18s %-10s %-35s\n" "$teacher" "$code" "$cname"
    done < "$TEACHER_COURSES_FILE"

    pause
}

# ══════════════════════════════════════════════════════════════════════════════
# ENROLLMENT MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

_admin_enrollment_management() {
    while true; do
        print_header
        print_menu "Enrollment Management" \
            "1:✅  Auto-Enroll Batch for Current Semester" \
            "2:📋  View Enrollments for a Batch" \
            "0:◀️   Back"

        case "$MENU_CHOICE" in
            1) _auto_enroll_batch ;;
            2) _view_enrollments ;;
            0) return ;;
            *) print_error "Invalid choice."; pause ;;
        esac
    done
}

_auto_enroll_batch() {
    print_header
    if ! pick_batch; then return; fi
    local bid="$PICKED_ID"

    local level term
    level=$(get_batch_field "$bid" 3)
    term=$(get_batch_field  "$bid" 4)

    echo ""
    echo "  Enrolling batch '$bid' into Level-${level} Term-${term}..."

    local students=()
    while IFS='|' read -r uname _ role _ batch _; do
        [[ "$role" == "student" && "$batch" == "$bid" ]] && students+=("$uname")
    done < "$USERS_FILE"

    if [[ ${#students[@]} -eq 0 ]]; then
        print_error "No students found in batch '$bid'."; pause; return
    fi

    local courses=()
    while IFS='|' read -r code _ _ l t _; do
        [[ "$l" == "$level" && "$t" == "$term" ]] && courses+=("$code")
    done < "$COURSES_FILE"

    if [[ ${#courses[@]} -eq 0 ]]; then
        print_error "No courses found for Level-${level} Term-${term}."; pause; return
    fi

    local count=0
    for code in "${courses[@]}"; do
        ensure_course_dir "$code"
        for student in "${students[@]}"; do
            if ! grep -q "^${student}|${bid}|${code}|" "$ENROLLMENTS_FILE"; then
                echo "${student}|${bid}|${code}|${level}|${term}|active" >> "$ENROLLMENTS_FILE"
                ((count++))
            fi
        done
    done

    log_action "$SESSION_USERNAME" "ENROLL_BATCH:${bid}:L${level}T${term}"
    echo ""
    echo "  Students : ${#students[@]}"
    echo "  Courses  : ${#courses[@]}"
    print_success "$count new enrollment records created."
    pause
}

_view_enrollments() {
    print_header
    if ! pick_batch; then return; fi
    local bid="$PICKED_ID"

    local cur_sem=""
    echo ""
    echo "  Enrollments for batch: $bid"

    while IFS='|' read -r uname b_id code level term status; do
        [[ "$b_id" != "$bid" ]] && continue
        local sem="Level-${level} Term-${term}"
        if [[ "$sem" != "$cur_sem" ]]; then
            echo ""
            echo "  --- $sem  [$status] ---"
            printf "  %-15s %-10s %s\n" "Student" "Code" "Course"
            echo "$DIV"
            cur_sem="$sem"
        fi
        local cname; cname=$(get_course_field "$code" 2)
        printf "  %-15s %-10s %s\n" "$uname" "$code" "$cname"
    done < "$ENROLLMENTS_FILE"

    pause
}

# ══════════════════════════════════════════════════════════════════════════════
# REPORTS
# ══════════════════════════════════════════════════════════════════════════════

_admin_reports() {
    while true; do
        print_header
        print_menu "Reports" \
            "1:📊  Grade Sheet by Course" \
            "2:📁  Full Batch Academic Report" \
            "0:◀️   Back"

        case "$MENU_CHOICE" in
            1) _report_grade_sheet ;;
            2) _report_batch ;;
            0) return ;;
            *) print_error "Invalid choice."; pause ;;
        esac
    done
}

_report_grade_sheet() {
    print_header
    if ! pick_course; then return; fi
    local code="$PICKED_ID"

    local gf; gf=$(get_grade_file "$code")
    local cname; cname=$(get_course_field "$code" 2)

    echo ""
    echo "  Course: [$code] $cname"
    printf "\n  %-15s %-12s %-7s %-7s %-20s\n" "Username" "Batch" "Grade" "Points" "Timestamp"
    echo "$DIV"

    if [[ ! -s "$gf" ]]; then
        echo "  No grades recorded yet."
    else
        while IFS='|' read -r uname bid grade pts ts; do
            printf "  %-15s %-12s %-7s %-7s %-20s\n" "$uname" "$bid" "$grade" "$pts" "$ts"
        done < "$gf"
    fi
    pause
}

_report_batch() {
    print_header
    print_section "Full Batch Academic Report"
    echo ""
    if ! pick_batch; then return; fi
    local bid="$PICKED_ID"
    
    while IFS='|' read -r uname fullname role _ batch _; do
        [[ "$role" != "student" || "$batch" != "$bid" ]] && continue

        echo ""
        echo "  Student : $fullname  ($uname)"
        printf "  %-10s %-38s %-7s %-5s %s\n" "Code" "Course" "Credits" "Grade" "Points"
        echo "$DIV"

        local total_pts=0 total_creds=0
        while IFS='|' read -r eu eb code level term status; do
            [[ "$eu" != "$uname" || "$eb" != "$bid" || "$status" != "completed" ]] && continue
            local cname credits grade pts
            cname=$(get_course_field "$code" 2)
            credits=$(get_course_field "$code" 3)
            grade="--" pts="--"
            local gf; gf=$(get_grade_file "$code")
            if [[ -f "$gf" ]]; then
                local line; line=$(grep "^${uname}|${bid}|" "$gf" | head -1)
                if [[ -n "$line" ]]; then
                    grade=$(echo "$line" | cut -d'|' -f3)
                    pts=$(echo "$line" | cut -d'|' -f4)
                    total_pts=$(awk -v tp="$total_pts" -v p="$pts" -v c="$credits" \
                        'BEGIN{printf "%.4f", tp + p*c}')
                    total_creds=$(awk -v tc="$total_creds" -v c="$credits" \
                        'BEGIN{printf "%.2f", tc + c}')
                fi
            fi
            printf "  %-10s %-38s %-7s %-5s %s\n" "$code" "$cname" "$credits" "$grade" "$pts"
        done < "$ENROLLMENTS_FILE"

        echo ""
        if awk -v tc="$total_creds" 'BEGIN{exit !(tc+0 > 0)}'; then
            local cgpa; cgpa=$(awk -v tp="$total_pts" -v tc="$total_creds" \
                'BEGIN{printf "%.2f", tp/tc}')
            printf "  %-30s Credits: %-8s CGPA: %s\n" "" "$total_creds" "$cgpa"
        else
            echo "  No graded courses yet."
        fi
    done < "$USERS_FILE"

    pause
}

# ══════════════════════════════════════════════════════════════════════════════
# ACTIVITY LOG
# ══════════════════════════════════════════════════════════════════════════════

_admin_view_log() {
    print_header
    print_section "Activity Log (last 40 entries)"
    printf "\n  %-20s %-15s %s\n" "Timestamp" "User" "Action"
    echo "$DIV"
    tail -40 "$ACTIVITY_LOG" | while IFS='|' read -r ts user action; do
        printf "  %-20s %-15s %s\n" "$ts" "$user" "$action"
    done
    pause
}
