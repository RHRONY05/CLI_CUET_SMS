#!/bin/bash
# teacher_panel.sh — Teacher dashboard

teacher_panel() {
    while true; do
        print_header
        echo "  👨‍🏫  Logged in as: $SESSION_FULLNAME (Teacher)"
        print_menu "Teacher Panel" \
            "1:📚  My Courses" \
            "2:👥  View Enrolled Students" \
            "3:✏️   Enter / Update Grade" \
            "4:📊  View Grade Sheet" \
            "5:📢  Post Notice" \
            "6:📰  View Notices" \
            "7:🔑  Change Password" \
            "0:🚪  Logout"

        case "$MENU_CHOICE" in
            1) _teacher_my_courses ;;
            2) _teacher_view_students ;;
            3) _teacher_enter_grade ;;
            4) _teacher_grade_sheet ;;
            5) _teacher_post_notice ;;
            6) _teacher_view_notices ;;
            7) change_password "$SESSION_USERNAME" ;;
            0) do_logout; return ;;
            *) print_error "Invalid choice."; pause ;;
        esac
    done
}

# ── Get list of courses assigned to the current teacher ───────────────────────

_get_my_courses() {
    grep "^${SESSION_USERNAME}|" "$TEACHER_COURSES_FILE" 2>/dev/null | cut -d'|' -f2
}

# ── My Courses ────────────────────────────────────────────────────────────────

_teacher_my_courses() {
    print_header
    print_section "My Courses"
    printf "\n  %-10s %-40s %-8s %-18s %s\n" "Code" "Course Name" "Credits" "Semester" "Type"
    echo "$DIV"

    local found=0
    while IFS= read -r code; do
        local name credits level term type
        name=$(get_course_field    "$code" 2)
        credits=$(get_course_field "$code" 3)
        level=$(get_course_field   "$code" 4)
        term=$(get_course_field    "$code" 5)
        type=$(get_course_field    "$code" 6)
        printf "  %-10s %-40s %-8s %-18s %s\n" \
            "$code" "$name" "$credits" "Level-${level} Term-${term}" "$type"
        found=1
    done < <(_get_my_courses)

    [[ "$found" -eq 0 ]] && echo "  No courses assigned. Ask admin to assign courses."
    pause
}

# ── View Enrolled Students ────────────────────────────────────────────────────

_teacher_view_students() {
    print_header
    print_section "View Enrolled Students"
    echo ""

    local code
    code=$(_pick_my_course) || { pause; return; }

    local cname; cname=$(get_course_field "$code" 2)
    echo ""
    echo "  Course: [$code] $cname"
    printf "\n  %-15s %-28s %-12s %s\n" "Username" "Full Name" "Batch" "Status"
    echo "$DIV"

    local count=0
    while IFS='|' read -r uname bid ec_code level term status; do
        [[ "$ec_code" != "$code" ]] && continue
        local fullname; fullname=$(get_user_field "$uname" 2)
        printf "  %-15s %-28s %-12s %s\n" "$uname" "$fullname" "$bid" "$status"
        ((count++))
    done < "$ENROLLMENTS_FILE"

    echo ""
    echo "  Total enrolled: $count"
    pause
}

# ── Enter / Update Grade ──────────────────────────────────────────────────────

_teacher_enter_grade() {
    print_header
    print_section "Enter / Update Grade"
    echo ""

    local code
    code=$(_pick_my_course) || { pause; return; }

    local cname; cname=$(get_course_field "$code" 2)
    echo ""
    echo "  Course: [$code] $cname"
    echo ""

    # Show enrolled students with current grades
    clear_picker
    local gf; gf=$(get_grade_file "$code")
    while IFS='|' read -r uname bid ec_code level term status; do
        [[ "$ec_code" != "$code" ]] && continue
        local fullname; fullname=$(get_user_field "$uname" 2)
        local cur_grade="--"
        if [[ -f "$gf" ]]; then
            local line; line=$(grep "^${uname}|${bid}|" "$gf" | head -1)
            [[ -n "$line" ]] && cur_grade=$(echo "$line" | cut -d'|' -f3)
        fi
        PICKER_KEYS+=("$uname")
        PICKER_LABELS+=("$uname - $fullname ($bid) [Grade: $cur_grade]")
    done < "$ENROLLMENTS_FILE"

    if ! _render_picker "Select Student to Grade"; then return; fi
    local target_user="$PICKED_ID"

    local bid; bid=$(grep "^${target_user}|[^|]*|${code}|" "$ENROLLMENTS_FILE" | head -1 | cut -d'|' -f2)

    echo ""
    echo "  Valid grades: A+  A  A-  B+  B  B-  C+  C  D  F"
    local grade
    while true; do
        read -rp "  Grade for $target_user: " grade
        grade=$(trim "$grade")
        if is_valid_grade "$grade"; then break; fi
        print_error "Invalid grade. Use: A+ A A- B+ B B- C+ C D F"
    done

    local pts; pts=$(grade_to_points "$grade")
    ensure_course_dir "$code"

    # Remove existing entry if any, then add new
    local tmp; tmp=$(mktemp)
    grep -v "^${target_user}|${bid}|" "$gf" > "$tmp"
    echo "${target_user}|${bid}|${grade}|${pts}|$(date '+%Y-%m-%d %H:%M:%S')" >> "$tmp"
    mv "$tmp" "$gf"

    log_action "$SESSION_USERNAME" "GRADE_ENTERED:${code}:${target_user}:${grade}"
    print_success "Grade '$grade' saved for $target_user in $code."
    pause
}

# ── View Grade Sheet ──────────────────────────────────────────────────────────

_teacher_grade_sheet() {
    print_header
    print_section "Grade Sheet"
    echo ""

    local code
    code=$(_pick_my_course) || { pause; return; }

    local cname; cname=$(get_course_field "$code" 2)
    local gf; gf=$(get_grade_file "$code")

    echo ""
    echo "  Course: [$code] $cname"
    printf "\n  %-15s %-12s %-28s %-7s %-7s %s\n" \
        "Username" "Batch" "Full Name" "Grade" "Points" "Date"
    echo "$DIV"

    if [[ ! -s "$gf" ]]; then
        echo "  No grades entered yet."
    else
        local graded=0 total_pts=0 total_creds=0
        local credits; credits=$(get_course_field "$code" 3)
        while IFS='|' read -r uname bid grade pts ts; do
            local fullname; fullname=$(get_user_field "$uname" 2)
            printf "  %-15s %-12s %-28s %-7s %-7s %s\n" \
                "$uname" "$bid" "$fullname" "$grade" "$pts" "${ts:0:10}"
            ((graded++))
            total_pts=$(awk -v tp="$total_pts" -v p="$pts" 'BEGIN{printf "%.4f", tp+p}')
        done < "$gf"
        echo ""
        if [[ "$graded" -gt 0 ]]; then
            local avg; avg=$(awk -v tp="$total_pts" -v n="$graded" 'BEGIN{printf "%.2f", tp/n}')
            echo "  Graded: $graded  |  Class Average Points: $avg"
        fi
    fi
    pause
}

# ── Notices ───────────────────────────────────────────────────────────────────

_teacher_post_notice() {
    print_header
    print_section "Post Notice"
    echo ""

    local code
    code=$(_pick_my_course) || { pause; return; }

    local cname; cname=$(get_course_field "$code" 2)
    echo "  Course: [$code] $cname"
    echo ""

    local title
    while true; do
        read -rp "  Notice Title  : " title
        title=$(trim "$title")
        [[ -n "$title" ]] && break
        print_error "Title cannot be empty."
    done

    local msg
    while true; do
        read -rp "  Message       : " msg
        msg=$(trim "$msg")
        [[ -n "$msg" ]] && break
        print_error "Message cannot be empty."
    done

    ensure_course_dir "$code"
    local nf; nf=$(get_notices_file "$code")
    local nid; nid="N$(date +%s)"
    echo "${nid}|${title}|${msg}|${SESSION_USERNAME}|$(date '+%Y-%m-%d %H:%M:%S')" >> "$nf"

    log_action "$SESSION_USERNAME" "POST_NOTICE:${code}:${title}"
    print_success "Notice posted to $code."
    pause
}

_teacher_view_notices() {
    print_header
    print_section "View Notices"
    echo ""

    local code
    code=$(_pick_my_course) || { pause; return; }

    local cname; cname=$(get_course_field "$code" 2)
    local nf; nf=$(get_notices_file "$code")

    echo ""
    echo "  Notices for [$code] $cname"
    echo "$DIV"

    if [[ ! -s "$nf" ]]; then
        echo "  No notices posted yet."
    else
        local n=1
        while IFS='|' read -r nid title msg author ts; do
            echo ""
            echo "  [$n] $title"
            echo "      Posted by: $author on ${ts:0:10}"
            echo "      $msg"
            ((n++))
        done < "$nf"
    fi
    pause
}

# ── Helper: pick from teacher's assigned courses ──────────────────────────────

_pick_my_course() {
    clear_picker
    while IFS= read -r code; do
        if [[ -n "$code" ]]; then
            local cname; cname=$(get_course_field "$code" 2)
            PICKER_KEYS+=("$code")
            PICKER_LABELS+=("[$code] $cname")
        fi
    done < <(_get_my_courses)

    if [[ ${#PICKER_KEYS[@]} -eq 0 ]]; then
        print_error "No courses assigned to you." >&2
        return 1
    fi

    if ! _render_picker "Your Assigned Courses" >&2; then
        return 1
    fi

    echo "$PICKED_ID"
}
