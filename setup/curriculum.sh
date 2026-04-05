#!/bin/bash
# curriculum.sh — Load the pre-defined CUET CSE 8-semester curriculum
# Safe to run multiple times (skips existing courses)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
COURSES_FILE="$BASE_DIR/db/courses.txt"

mkdir -p "$BASE_DIR/db"
touch "$COURSES_FILE"

# Format: code|name|credits|level|term|type
_add_course() {
    local code="$1"
    if ! grep -q "^${code}|" "$COURSES_FILE"; then
        echo "$1|$2|$3|$4|$5|$6" >> "$COURSES_FILE"
    fi
}

load_curriculum() {
    echo "  Loading CUET CSE curriculum..."

    # ── Level 1, Term 1 ───────────────────────────────────────────────────────
    _add_course "CSE141"  "Structured Programming"              "3.00" "1" "1" "theory"
    _add_course "EE181"   "Basic Electrical Engineering"        "3.00" "1" "1" "theory"
    _add_course "MATH141" "Differential and Integral Calculus"  "3.00" "1" "1" "theory"
    _add_course "PHY141"  "Physics I"                           "3.00" "1" "1" "theory"
    _add_course "HUM141"  "English"                             "2.00" "1" "1" "theory"
    _add_course "CSE100"  "Computer Fundamentals and Ethics"    "0.75" "1" "1" "sessional"
    _add_course "CSE142"  "Structured Programming Sessional"    "1.50" "1" "1" "sessional"
    _add_course "EE182"   "Basic Electrical Engineering Sessional" "1.50" "1" "1" "sessional"
    _add_course "PHY142"  "Physics I Sessional"                 "1.50" "1" "1" "sessional"

    # ── Level 1, Term 2 ───────────────────────────────────────────────────────
    _add_course "CSE143"  "Object Oriented Programming"         "3.00" "1" "2" "theory"
    _add_course "EE183"   "Electronics"                         "3.00" "1" "2" "theory"
    _add_course "MATH143" "Coordinate Geometry and Vector Analysis" "3.00" "1" "2" "theory"
    _add_course "PHY143"  "Physics II"                          "3.00" "1" "2" "theory"
    _add_course "HUM143"  "Economics"                           "2.00" "1" "2" "theory"
    _add_course "CSE144"  "OOP Sessional"                       "1.50" "1" "2" "sessional"
    _add_course "EE184"   "Electronics Sessional"               "1.50" "1" "2" "sessional"
    _add_course "PHY144"  "Physics II Sessional"                "1.50" "1" "2" "sessional"

    # ── Level 2, Term 1 ───────────────────────────────────────────────────────
    _add_course "CSE241"  "Data Structures"                     "3.00" "2" "1" "theory"
    _add_course "CSE243"  "Digital Electronics and Pulse Techniques" "3.00" "2" "1" "theory"
    _add_course "MATH241" "Complex Variable, Laplace and Fourier" "3.00" "2" "1" "theory"
    _add_course "CSE245"  "Discrete Mathematics"                "3.00" "2" "1" "theory"
    _add_course "HUM241"  "Sociology"                           "2.00" "2" "1" "theory"
    _add_course "CSE242"  "Data Structures Sessional"           "1.50" "2" "1" "sessional"
    _add_course "CSE244"  "Digital Electronics Sessional"       "1.50" "2" "1" "sessional"
    _add_course "MATH242" "Mathematics Sessional"               "0.75" "2" "1" "sessional"

    # ── Level 2, Term 2 ───────────────────────────────────────────────────────
    _add_course "CSE247"  "Algorithm Design and Analysis"       "3.00" "2" "2" "theory"
    _add_course "CSE249"  "Computer Organization and Architecture" "3.00" "2" "2" "theory"
    _add_course "MATH243" "Statistics and Probability"          "3.00" "2" "2" "theory"
    _add_course "CSE251"  "Theory of Computation"               "3.00" "2" "2" "theory"
    _add_course "HUM243"  "Technical Writing"                   "2.00" "2" "2" "theory"
    _add_course "CSE248"  "Algorithm Design Sessional"          "1.50" "2" "2" "sessional"
    _add_course "CSE250"  "Computer Architecture Sessional"     "1.50" "2" "2" "sessional"

    # ── Level 3, Term 1 ───────────────────────────────────────────────────────
    _add_course "CSE341"  "Operating Systems"                   "3.00" "3" "1" "theory"
    _add_course "CSE343"  "Database Management Systems"         "3.00" "3" "1" "theory"
    _add_course "CSE345"  "Computer Networks"                   "3.00" "3" "1" "theory"
    _add_course "CSE347"  "Software Engineering"                "3.00" "3" "1" "theory"
    _add_course "HUM341"  "Management"                          "2.00" "3" "1" "theory"
    _add_course "CSE342"  "Operating Systems Sessional"         "1.50" "3" "1" "sessional"
    _add_course "CSE344"  "Database Management Sessional"       "1.50" "3" "1" "sessional"
    _add_course "CSE346"  "Networking Sessional"                "1.50" "3" "1" "sessional"

    # ── Level 3, Term 2 ───────────────────────────────────────────────────────
    _add_course "CSE349"  "Compiler Design"                     "3.00" "3" "2" "theory"
    _add_course "CSE351"  "Artificial Intelligence"             "3.00" "3" "2" "theory"
    _add_course "CSE353"  "Computer Graphics"                   "3.00" "3" "2" "theory"
    _add_course "CSE355"  "Microprocessors and Embedded Systems" "3.00" "3" "2" "theory"
    _add_course "HUM343"  "Accounting"                          "2.00" "3" "2" "theory"
    _add_course "CSE350"  "Compiler Design Sessional"           "1.50" "3" "2" "sessional"
    _add_course "CSE352"  "AI Sessional"                        "1.50" "3" "2" "sessional"
    _add_course "CSE356"  "Microprocessors Sessional"           "1.50" "3" "2" "sessional"

    # ── Level 4, Term 1 ───────────────────────────────────────────────────────
    _add_course "CSE441"  "Machine Learning"                    "3.00" "4" "1" "theory"
    _add_course "CSE443"  "Information Security"                "3.00" "4" "1" "theory"
    _add_course "CSE445"  "Distributed Systems"                 "3.00" "4" "1" "theory"
    _add_course "CSE447"  "Advanced Database Systems"           "3.00" "4" "1" "theory"
    _add_course "CSE449"  "Elective I"                          "3.00" "4" "1" "theory"
    _add_course "CSE442"  "Machine Learning Sessional"          "1.50" "4" "1" "sessional"
    _add_course "CSE444"  "Information Security Sessional"      "1.50" "4" "1" "sessional"

    # ── Level 4, Term 2 ───────────────────────────────────────────────────────
    _add_course "CSE451"  "Thesis and Project"                  "6.00" "4" "2" "theory"
    _add_course "CSE453"  "Elective II"                         "3.00" "4" "2" "theory"
    _add_course "CSE455"  "Elective III"                        "3.00" "4" "2" "theory"
    _add_course "CSE457"  "Professional Ethics and Society"     "2.00" "4" "2" "theory"

    echo "  Curriculum loaded. $(wc -l < "$COURSES_FILE") courses in database."
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    load_curriculum
fi
