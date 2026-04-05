#!/bin/bash
# demo_data.sh — Load test data for demonstration
# Creates: 1 admin, 2 teachers, 1 batch (CSE2024) with 3 students
# Batch is at Level 2 Term 1 (active); L1T1 and L1T2 are completed with grades.
#
# Test Credentials:
#   Admin   : admin        / Admin@123
#   Teacher : prof_karim   / Teacher@123
#   Teacher : prof_rahman  / Teacher@123
#   Student : rony2024     / Student@123
#   Student : sara2024     / Student@123
#   Student : karim2024    / Student@123

_SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_PROJ_DIR="$(dirname "$_SETUP_DIR")"

source "$_PROJ_DIR/src/utils.sh"

init_dirs

# ── Load curriculum first ─────────────────────────────────────────────────────
source "$_SETUP_DIR/curriculum.sh"
load_curriculum

echo ""
echo "  Loading demo data..."

# ── Helper ────────────────────────────────────────────────────────────────────

_add_user() {
    local uname="$1" fullname="$2" role="$3" pass="$4" batch="$5" force_pw="$6"
    if ! user_exists "$uname"; then
        local hash; hash=$(hash_password "$pass")
        echo "${uname}|${fullname}|${role}|${hash}|${batch}|${force_pw}" >> "$USERS_FILE"
        echo "  + User: $uname ($role)"
    fi
}

_add_batch() {
    local bid="$1" year="$2" level="$3" term="$4" status="$5"
    if ! batch_exists "$bid"; then
        echo "${bid}|${year}|${level}|${term}|${status}" >> "$BATCHES_FILE"
        echo "  + Batch: $bid (Level-$level Term-$term, $status)"
    fi
}

_enroll() {
    local uname="$1" bid="$2" code="$3" level="$4" term="$5" status="$6"
    if ! grep -q "^${uname}|${bid}|${code}|" "$ENROLLMENTS_FILE"; then
        echo "${uname}|${bid}|${code}|${level}|${term}|${status}" >> "$ENROLLMENTS_FILE"
    fi
}

_add_grade() {
    local code="$1" uname="$2" bid="$3" grade="$4"
    ensure_course_dir "$code"
    local gf; gf=$(get_grade_file "$code")
    local pts; pts=$(grade_to_points "$grade")
    if ! grep -q "^${uname}|${bid}|" "$gf"; then
        echo "${uname}|${bid}|${grade}|${pts}|$(date '+%Y-%m-%d %H:%M:%S')" >> "$gf"
    fi
}

_assign_teacher() {
    local teacher="$1" code="$2"
    if ! grep -q "^${teacher}|${code}$" "$TEACHER_COURSES_FILE"; then
        echo "${teacher}|${code}" >> "$TEACHER_COURSES_FILE"
    fi
}

_add_notice() {
    local code="$1" title="$2" msg="$3" author="$4"
    ensure_course_dir "$code"
    local nf; nf=$(get_notices_file "$code")
    local nid; nid="N$(date +%s%N | tail -c 6)"
    echo "${nid}|${title}|${msg}|${author}|$(date '+%Y-%m-%d %H:%M:%S')" >> "$nf"
}

# ── Users ─────────────────────────────────────────────────────────────────────

_add_user "admin"      "System Administrator"   "admin"   "Admin@123"   ""        "0"
_add_user "prof_karim" "Dr. Abdul Karim"        "teacher" "Teacher@123" ""        "0"
_add_user "prof_rahman" "Dr. Md. Rashidur Rahman" "teacher" "Teacher@123" ""      "0"
_add_user "rony2024"   "Rony Ahmed"             "student" "Student@123" "CSE2024" "0"
_add_user "sara2024"   "Sara Islam"             "student" "Student@123" "CSE2024" "0"
_add_user "karim2024"  "Karim Hossain"          "student" "Student@123" "CSE2024" "0"

# ── Batch ─────────────────────────────────────────────────────────────────────

_add_batch "CSE2024" "2024" "2" "1" "active"

# ── Teacher → Course assignments ──────────────────────────────────────────────

# L1T1 courses (completed semester)
_assign_teacher "prof_karim"  "CSE141"
_assign_teacher "prof_karim"  "CSE142"
_assign_teacher "prof_rahman" "MATH141"
_assign_teacher "prof_rahman" "CSE100"

# L1T2 courses (completed semester)
_assign_teacher "prof_karim"  "CSE143"
_assign_teacher "prof_karim"  "CSE144"
_assign_teacher "prof_rahman" "MATH143"

# L2T1 courses (active semester)
_assign_teacher "prof_karim"  "CSE241"
_assign_teacher "prof_karim"  "CSE242"
_assign_teacher "prof_karim"  "CSE243"
_assign_teacher "prof_karim"  "CSE244"
_assign_teacher "prof_rahman" "MATH241"
_assign_teacher "prof_rahman" "CSE245"

echo "  + Teacher-course assignments done."

# ── Enrollments: L1T1 (completed) ────────────────────────────────────────────

for student in rony2024 sara2024 karim2024; do
    for code in CSE141 EE181 MATH141 PHY141 HUM141 CSE100 CSE142 EE182 PHY142; do
        _enroll "$student" "CSE2024" "$code" "1" "1" "completed"
    done
done

# ── Enrollments: L1T2 (completed) ────────────────────────────────────────────

for student in rony2024 sara2024 karim2024; do
    for code in CSE143 EE183 MATH143 PHY143 HUM143 CSE144 EE184 PHY144; do
        _enroll "$student" "CSE2024" "$code" "1" "2" "completed"
    done
done

# ── Enrollments: L2T1 (active) ───────────────────────────────────────────────

for student in rony2024 sara2024 karim2024; do
    for code in CSE241 CSE243 MATH241 CSE245 HUM241 CSE242 CSE244 MATH242; do
        _enroll "$student" "CSE2024" "$code" "2" "1" "active"
    done
done

echo "  + Enrollments done (L1T1 completed, L1T2 completed, L2T1 active)."

# ── Grades: L1T1 ─────────────────────────────────────────────────────────────

# rony2024
_add_grade "CSE141" "rony2024" "CSE2024" "A+"
_add_grade "EE181"  "rony2024" "CSE2024" "A"
_add_grade "MATH141" "rony2024" "CSE2024" "A+"
_add_grade "PHY141" "rony2024" "CSE2024" "A"
_add_grade "HUM141" "rony2024" "CSE2024" "A+"
_add_grade "CSE100" "rony2024" "CSE2024" "A+"
_add_grade "CSE142" "rony2024" "CSE2024" "A"
_add_grade "EE182"  "rony2024" "CSE2024" "A-"
_add_grade "PHY142" "rony2024" "CSE2024" "A"

# sara2024
_add_grade "CSE141" "sara2024" "CSE2024" "A+"
_add_grade "EE181"  "sara2024" "CSE2024" "A+"
_add_grade "MATH141" "sara2024" "CSE2024" "A"
_add_grade "PHY141" "sara2024" "CSE2024" "A+"
_add_grade "HUM141" "sara2024" "CSE2024" "A+"
_add_grade "CSE100" "sara2024" "CSE2024" "A+"
_add_grade "CSE142" "sara2024" "CSE2024" "A+"
_add_grade "EE182"  "sara2024" "CSE2024" "A"
_add_grade "PHY142" "sara2024" "CSE2024" "A+"

# karim2024
_add_grade "CSE141" "karim2024" "CSE2024" "B+"
_add_grade "EE181"  "karim2024" "CSE2024" "B"
_add_grade "MATH141" "karim2024" "CSE2024" "B+"
_add_grade "PHY141" "karim2024" "CSE2024" "A-"
_add_grade "HUM141" "karim2024" "CSE2024" "A"
_add_grade "CSE100" "karim2024" "CSE2024" "A"
_add_grade "CSE142" "karim2024" "CSE2024" "B+"
_add_grade "EE182"  "karim2024" "CSE2024" "B"
_add_grade "PHY142" "karim2024" "CSE2024" "B+"

# ── Grades: L1T2 ─────────────────────────────────────────────────────────────

# rony2024
_add_grade "CSE143" "rony2024" "CSE2024" "A+"
_add_grade "EE183"  "rony2024" "CSE2024" "A-"
_add_grade "MATH143" "rony2024" "CSE2024" "A"
_add_grade "PHY143" "rony2024" "CSE2024" "A-"
_add_grade "HUM143" "rony2024" "CSE2024" "A"
_add_grade "CSE144" "rony2024" "CSE2024" "A+"
_add_grade "EE184"  "rony2024" "CSE2024" "A-"
_add_grade "PHY144" "rony2024" "CSE2024" "A"

# sara2024
_add_grade "CSE143" "sara2024" "CSE2024" "A+"
_add_grade "EE183"  "sara2024" "CSE2024" "A"
_add_grade "MATH143" "sara2024" "CSE2024" "A+"
_add_grade "PHY143" "sara2024" "CSE2024" "A"
_add_grade "HUM143" "sara2024" "CSE2024" "A+"
_add_grade "CSE144" "sara2024" "CSE2024" "A+"
_add_grade "EE184"  "sara2024" "CSE2024" "A"
_add_grade "PHY144" "sara2024" "CSE2024" "A+"

# karim2024
_add_grade "CSE143" "karim2024" "CSE2024" "B+"
_add_grade "EE183"  "karim2024" "CSE2024" "C+"
_add_grade "MATH143" "karim2024" "CSE2024" "B"
_add_grade "PHY143" "karim2024" "CSE2024" "B+"
_add_grade "HUM143" "karim2024" "CSE2024" "A-"
_add_grade "CSE144" "karim2024" "CSE2024" "B+"
_add_grade "EE184"  "karim2024" "CSE2024" "C+"
_add_grade "PHY144" "karim2024" "CSE2024" "B"

echo "  + Grades added for L1T1 and L1T2."

# ── Sample notices ────────────────────────────────────────────────────────────

_add_notice "CSE241" "Welcome to Data Structures" \
    "Welcome to CSE241. Course materials will be shared on the portal." \
    "prof_karim"
_add_notice "CSE241" "Assignment 1 Released" \
    "Assignment 1 on Linked Lists is due by end of this week." \
    "prof_karim"
_add_notice "MATH241" "Tutorial Schedule" \
    "Tutorial sessions every Saturday 9am-11am in Room 301." \
    "prof_rahman"

echo "  + Sample notices added."

echo ""
echo "  ============================================================"
echo "  Demo data loaded successfully!"
echo ""
echo "  Test Credentials:"
echo "    Admin   : admin        / Admin@123"
echo "    Teacher : prof_karim   / Teacher@123"
echo "    Teacher : prof_rahman  / Teacher@123"
echo "    Student : rony2024     / Student@123"
echo "    Student : sara2024     / Student@123"
echo "    Student : karim2024    / Student@123"
echo "  ============================================================"
echo ""
