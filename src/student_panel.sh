#!/bin/bash
# student_panel.sh — Student dashboard

student_panel() {
    while true; do
        print_header
        echo "  🎓  Logged in as: $SESSION_FULLNAME (Student)"
        print_menu "Student Panel" \
            "1:🏠  Dashboard" \
            "2:📚  My Current Courses" \
            "3:📊  My Grades (Current Semester)" \
            "4:🎓  Academic Record and CGPA" \
            "5:📢  Course Notices" \
            "6:🔑  Change Password" \
            "0:🚪  Logout"

        case "$MENU_CHOICE" in
            1) _student_dashboard ;;
            2) _student_current_courses ;;
            3) _student_current_grades ;;
            4) _student_full_record ;;
            5) _student_notices ;;
            6) change_password "$SESSION_USERNAME" ;;
            0) do_logout; return ;;
            *) print_error "Invalid choice."; pause ;;
        esac
    done
}

# ── Dashboard ─────────────────────────────────────────────────────────────────

_student_dashboard() {
    local bid="$SESSION_BATCH"

    print_header
    print_section "My Dashboard"
    echo ""
    echo "  Name     : $SESSION_FULLNAME"
    echo "  Username : $SESSION_USERNAME"
    echo "  Batch    : $bid"

    if batch_exists "$bid"; then
        local level term status
        level=$(get_batch_field "$bid" 3)
        term=$(get_batch_field  "$bid" 4)
        status=$(get_batch_field "$bid" 5)
        echo "  Semester : Level-${level} Term-${term}"
        echo "  Status   : $status"
    fi

    echo ""
    echo "$DIV"

    # Quick CGPA from completed semesters
    local total_pts=0 total_creds=0
    while IFS='|' read -r uname b_id code level term status; do
        [[ "$uname" != "$SESSION_USERNAME" || "$b_id" != "$bid" || "$status" != "completed" ]] && continue
        local gf; gf=$(get_grade_file "$code")
        if [[ -f "$gf" ]]; then
            local line; line=$(grep "^${SESSION_USERNAME}|${bid}|" "$gf" | head -1)
            if [[ -n "$line" ]]; then
                local pts credits
                pts=$(echo "$line" | cut -d'|' -f4)
                credits=$(get_course_field "$code" 3)
                total_pts=$(awk -v tp="$total_pts" -v p="$pts" -v c="$credits" \
                    'BEGIN{printf "%.4f", tp + p*c}')
                total_creds=$(awk -v tc="$total_creds" -v c="$credits" \
                    'BEGIN{printf "%.2f", tc + c}')
            fi
        fi
    done < "$ENROLLMENTS_FILE"

    if awk -v tc="$total_creds" 'BEGIN{exit !(tc+0 > 0)}'; then
        local cgpa; cgpa=$(awk -v tp="$total_pts" -v tc="$total_creds" \
            'BEGIN{printf "%.2f", tp/tc}')
        echo ""
        echo "  Completed Credits : $total_creds"
        echo "  Current CGPA      : $cgpa"
    else
        echo ""
        echo "  No completed semesters yet."
    fi

    pause
}

# ── Current Courses ───────────────────────────────────────────────────────────

_student_current_courses() {
    local bid="$SESSION_BATCH"
    local level term
    level=$(get_batch_field "$bid" 3)
    term=$(get_batch_field  "$bid" 4)

    print_header
    print_section "My Current Courses — Level-${level} Term-${term}"
    printf "\n  %-10s %-40s %-8s %s\n" "Code" "Course Name" "Credits" "Type"
    echo "$DIV"

    local count=0
    while IFS='|' read -r uname b_id code l t status; do
        [[ "$uname" != "$SESSION_USERNAME" || "$b_id" != "$bid" || \
           "$l" != "$level" || "$t" != "$term" || "$status" != "active" ]] && continue
        local cname credits type
        cname=$(get_course_field   "$code" 2)
        credits=$(get_course_field "$code" 3)
        type=$(get_course_field    "$code" 6)
        printf "  %-10s %-40s %-8s %s\n" "$code" "$cname" "$credits" "$type"
        ((count++))
    done < "$ENROLLMENTS_FILE"

    echo ""
    [[ "$count" -eq 0 ]] && echo "  No active enrollments. Ask admin to enroll you." \
                         || echo "  Total: $count course(s)"
    pause
}

# ── Current Semester Grades ───────────────────────────────────────────────────

_student_current_grades() {
    local bid="$SESSION_BATCH"
    local level term
    level=$(get_batch_field "$bid" 3)
    term=$(get_batch_field  "$bid" 4)

    print_header
    print_section "My Grades — Level-${level} Term-${term} (Current)"
    printf "\n  %-10s %-38s %-8s %-6s %s\n" "Code" "Course" "Credits" "Grade" "Points"
    echo "$DIV"

    local sem_pts=0 sem_creds=0 graded=0
    while IFS='|' read -r uname b_id code l t status; do
        [[ "$uname" != "$SESSION_USERNAME" || "$b_id" != "$bid" || \
           "$l" != "$level" || "$t" != "$term" ]] && continue

        local cname credits grade pts
        cname=$(get_course_field   "$code" 2)
        credits=$(get_course_field "$code" 3)
        grade="--" pts="--"

        local gf; gf=$(get_grade_file "$code")
        if [[ -f "$gf" ]]; then
            local line; line=$(grep "^${SESSION_USERNAME}|${bid}|" "$gf" | head -1)
            if [[ -n "$line" ]]; then
                grade=$(echo "$line" | cut -d'|' -f3)
                pts=$(echo "$line" | cut -d'|' -f4)
                sem_pts=$(awk -v sp="$sem_pts" -v p="$pts" -v c="$credits" \
                    'BEGIN{printf "%.4f", sp + p*c}')
                sem_creds=$(awk -v sc="$sem_creds" -v c="$credits" \
                    'BEGIN{printf "%.2f", sc + c}')
                ((graded++))
            fi
        fi

        printf "  %-10s %-38s %-8s %-6s %s\n" "$code" "$cname" "$credits" "$grade" "$pts"
    done < "$ENROLLMENTS_FILE"

    echo ""
    if [[ "$graded" -gt 0 ]]; then
        local sgpa; sgpa=$(awk -v sp="$sem_pts" -v sc="$sem_creds" \
            'BEGIN{printf "%.2f", sp/sc}')
        echo "  Graded Credits : $sem_creds  |  Semester GPA : $sgpa"
    else
        echo "  Grades not published yet."
    fi

    pause
}

# ── Full Academic Record + CGPA ───────────────────────────────────────────────

_student_full_record() {
    local bid="$SESSION_BATCH"

    print_header
    print_section "Full Academic Record"
    echo "  Student : $SESSION_FULLNAME  ($SESSION_USERNAME)"
    echo "  Batch   : $bid"

    local overall_pts=0 overall_creds=0
    local cur_sem=""

    while IFS='|' read -r uname b_id code level term status; do
        [[ "$uname" != "$SESSION_USERNAME" || "$b_id" != "$bid" ]] && continue

        local sem="Level-${level} Term-${term}"
        if [[ "$sem" != "$cur_sem" ]]; then
            # Print semester GPA for previous semester if applicable
            if [[ -n "$cur_sem" && -n "$_sem_creds" ]]; then
                _print_sem_gpa "$_sem_pts" "$_sem_creds" "$_sem_status"
            fi
            echo ""
            echo "  ── $sem  [$status] ──"
            printf "  %-10s %-38s %-8s %-6s %s\n" "Code" "Course" "Credits" "Grade" "Points"
            echo "$DIV"
            cur_sem="$sem"
            _sem_pts=0; _sem_creds=0; _sem_status="$status"
        fi

        local cname credits grade pts
        cname=$(get_course_field   "$code" 2)
        credits=$(get_course_field "$code" 3)
        grade="--" pts="--"

        local gf; gf=$(get_grade_file "$code")
        if [[ -f "$gf" ]]; then
            local line; line=$(grep "^${SESSION_USERNAME}|${bid}|" "$gf" | head -1)
            if [[ -n "$line" ]]; then
                grade=$(echo "$line" | cut -d'|' -f3)
                pts=$(echo "$line" | cut -d'|' -f4)
                if [[ "$status" == "completed" ]]; then
                    overall_pts=$(awk -v op="$overall_pts" -v p="$pts" -v c="$credits" \
                        'BEGIN{printf "%.4f", op + p*c}')
                    overall_creds=$(awk -v oc="$overall_creds" -v c="$credits" \
                        'BEGIN{printf "%.2f", oc + c}')
                fi
                _sem_pts=$(awk -v sp="$_sem_pts" -v p="$pts" -v c="$credits" \
                    'BEGIN{printf "%.4f", sp + p*c}')
                _sem_creds=$(awk -v sc="$_sem_creds" -v c="$credits" \
                    'BEGIN{printf "%.2f", sc + c}')
            fi
        fi

        printf "  %-10s %-38s %-8s %-6s %s\n" "$code" "$cname" "$credits" "$grade" "$pts"
    done < "$ENROLLMENTS_FILE"

    # Print last semester GPA
    if [[ -n "$cur_sem" && -n "$_sem_creds" ]]; then
        _print_sem_gpa "$_sem_pts" "$_sem_creds" "$_sem_status"
    fi

    echo ""
    echo "$SEP"
    if awk -v oc="$overall_creds" 'BEGIN{exit !(oc+0 > 0)}'; then
        local cgpa; cgpa=$(awk -v op="$overall_pts" -v oc="$overall_creds" \
            'BEGIN{printf "%.2f", op/oc}')
        echo "  Completed Credits : $overall_creds"
        echo "  Cumulative GPA    : $cgpa"
    else
        echo "  No completed semesters with grades yet."
    fi

    pause
}

_print_sem_gpa() {
    local sem_pts="$1" sem_creds="$2" status="$3"
    if awk -v sc="$sem_creds" 'BEGIN{exit !(sc+0 > 0)}'; then
        local sgpa; sgpa=$(awk -v sp="$sem_pts" -v sc="$sem_creds" \
            'BEGIN{printf "%.2f", sp/sc}')
        printf "  %50s Credits: %-6s GPA: %s\n" "" "$sem_creds" "$sgpa"
    fi
}

# ── Course Notices ────────────────────────────────────────────────────────────

_student_notices() {
    local bid="$SESSION_BATCH"

    print_header
    print_section "Course Notices"
    echo ""

    clear_picker
    while IFS='|' read -r uname b_id code level term status; do
        [[ "$uname" != "$SESSION_USERNAME" || "$b_id" != "$bid" ]] && continue
        local cname; cname=$(get_course_field "$code" 2)
        PICKER_KEYS+=("$code")
        PICKER_LABELS+=("[$code] $cname (Level-$level Term-$term)")
    done < "$ENROLLMENTS_FILE"

    if ! _render_picker "Select Course to view Notices"; then return; fi
    local code="$PICKED_ID"

    local nf; nf=$(get_notices_file "$code")
    local cname; cname=$(get_course_field "$code" 2)

    echo ""
    echo "  Notices for [$code] $cname"
    echo "$DIV"

    if [[ ! -s "$nf" ]]; then
        echo "  No notices posted yet."
    else
        local n=1
        while IFS='|' read -r nid title msg author ts; do
            echo ""
            printf "  [%d] %s\n" "$n" "$title"
            printf "      Date   : %s\n" "${ts:0:10}"
            printf "      From   : %s\n" "$author"
            printf "      %s\n" "$msg"
            ((n++))
        done < "$nf"
    fi

    pause
}
