# Work Distribution — CUET CSE SMS Group Project

## Person 1 — Project Foundation & Entry Point

**Files:** `main.sh`, `src/ui.sh`, `src/utils.sh`, `setup/curriculum.sh`

**Topics to explain:**
- How the app starts and routes to roles (`main.sh`)
- The data model — all 6 file formats (`users.txt`, `batches.txt`, `courses.txt`, `enrollments.txt`, `teacher_courses.txt`, `grades.txt`)
- Helper functions: `get_user_field`, `get_course_field`, `is_enrolled`, etc.
- The UI system: `print_header`, `print_menu`, `print_section`, `pause`, `confirm`
- The 56-course curriculum structure (8 semesters × 7 courses each)

---

## Person 2 — Authentication & Security

**Files:** `src/auth.sh`, `setup/demo_data.sh`

**Topics to explain:**
- Login flow: username lookup → SHA-256 hash comparison
- Force password change on first login
- Session variables (`SESSION_USERNAME`, `SESSION_FULLNAME`, `SESSION_ROLE`)
- `do_logout` — how session is cleared
- `change_password` — old password verification + new password update
- How demo data populates all users, batches, enrollments, and grades (the test harness)

---

## Person 3 — Admin Panel: User & Batch Management

**Files:** `src/admin_panel.sh` (lines 1–300 approx)

**Functions to explain:**
- `admin_panel` — the main menu loop
- `_add_user_flow` — creating admin/teacher/student accounts
- `_list_users`, `_delete_user`, `_reset_password`
- `_create_batch`, `_advance_batch` — semester progression logic
- `_list_batches`, `_view_batch_students`

---

## Person 4 — Admin Panel: Courses, Enrollment & Reports

**Files:** `src/admin_panel.sh` (lines 300–734 approx)

**Functions to explain:**
- `_view_curriculum` — reading the course catalog
- `_assign_teacher`, `_remove_teacher_assignment`, `_view_teacher_assignments`
- `_auto_enroll_batch` — how all students in a batch get enrolled into a semester's courses automatically
- `_view_enrollments`
- `_report_grade_sheet`, `_report_batch` — aggregated CGPA and grade reporting
- `_admin_view_log` — activity audit trail

---

## Person 5 — Teacher & Student Panels

**Files:** `src/teacher_panel.sh`, `src/student_panel.sh`

**Topics to explain:**

**Teacher side:**
- `_get_my_courses` / `_pick_my_course` — how teachers see only their assigned courses
- `_teacher_view_students` — reading `enrollments.txt` filtered by course
- `_teacher_enter_grade` — writing to `courses/<code>/grades.txt`
- `_teacher_post_notice` / `_teacher_view_notices`

**Student side:**
- `_student_my_courses` — showing active enrollments
- `_student_grades` — reading grades per course
- `_student_cgpa` — calculating CGPA from weighted grade points
- `_student_notices` — viewing notices for enrolled courses

---

## Quick Reference

| Person | Files | Lines |
|--------|-------|-------|
| 1 | `main.sh` + `ui.sh` + `utils.sh` + `curriculum.sh` | ~446 |
| 2 | `auth.sh` + `demo_data.sh` | ~443 |
| 3 | `admin_panel.sh` (user/batch) | ~300 |
| 4 | `admin_panel.sh` (courses/enrollment/reports) | ~434 |
| 5 | `teacher_panel.sh` + `student_panel.sh` | ~607 |
