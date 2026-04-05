# CUET CSE Student Management System
### CSE 336: Operating Systems Sessional — CUET

A Role-Based Access Control (RBAC) CLI application built entirely in **Bash**. Runs as a single process — no `sudo`, no real Linux users, no external database. Authentication and access control are handled entirely in the application layer using plain text files.

---

## Project Structure

```
CLI_CUET_SMS/
├── main.sh                  ← Entry point — run this
├── src/
│   ├── auth.sh              ← Login, logout, session, password management
│   ├── admin_panel.sh       ← Admin dashboard and all sub-menus
│   ├── teacher_panel.sh     ← Teacher dashboard
│   ├── student_panel.sh     ← Student dashboard
│   ├── ui.sh                ← Terminal UI helpers (menus, headers, messages)
│   └── utils.sh             ← Shared utilities, file paths, DB helpers
├── setup/
│   ├── curriculum.sh        ← Loads the full 8-semester CUET CSE curriculum
│   └── demo_data.sh         ← Seeds demo users, batch, enrollments, and grades
└── db/                      ← Created automatically on first run
    ├── users.txt
    ├── batches.txt
    ├── courses.txt
    ├── enrollments.txt
    ├── teacher_courses.txt
    └── sessions/
```

---

## Quick Start (WSL / Ubuntu)

### 1 — Clone the repo

```bash
git clone https://github.com/RHRONY05/CLI_CUET_SMS.git
cd CLI_CUET_SMS
```

### 2a — Fresh start (no data)

```bash
bash main.sh
```

On first run, a setup wizard will prompt you to create the initial admin account.

### 2b — Start with demo data

```bash
bash main.sh --demo
```

This loads the full curriculum, 1 batch (CSE2024 at Level-2 Term-1), 3 students with 2 completed semesters and grades, 2 teachers, and sample notices — then drops you at the login screen.

---

## Demo Credentials

| Role    | Username     | Password     |
|---------|-------------|--------------|
| Admin   | `admin`      | `Admin@123`  |
| Teacher | `prof_karim` | `Teacher@123`|
| Teacher | `prof_rahman`| `Teacher@123`|
| Student | `rony2024`   | `Student@123`|
| Student | `sara2024`   | `Student@123`|
| Student | `karim2024`  | `Student@123`|

---

## Roles & Capabilities

| Role    | What they can do |
|---------|-----------------|
| Admin   | Manage users, create/advance batches, assign teachers to courses, auto-enroll batches, view reports and activity log |
| Teacher | Enter/update grades, post notices, view enrolled students for assigned courses |
| Student | View own grades, CGPA, enrolled courses, and course notices (read-only) |

---

## Features

### Admin Panel
- Add/delete users (student, teacher, admin)
- Reset any user's password
- Create batches and advance them semester by semester (L1T1 → L1T2 → ... → L4T2 → graduated)
- View students per batch
- Assign/remove teachers from courses
- Auto-enroll an entire batch into their current semester's courses
- Grade sheet report per course
- Full batch academic report with CGPA
- Activity log viewer (last 40 entries)

### Teacher Panel
- View courses assigned to them
- Enter and update student grades
- Post notices to course notice board
- View enrolled students per course

### Student Panel
- View enrolled courses per semester
- View own grades per course
- CGPA summary across all completed semesters
- Read course notices

---

## How It Works

### Authentication
- Passwords are hashed with **SHA-256** (`sha256sum`) and stored in `db/users.txt`
- Session state is held in shell variables (`SESSION_USERNAME`, `SESSION_ROLE`, etc.) — no temp files
- Force password change is enforced on first login when set by admin

### Data Format

**db/users.txt**
```
username|fullname|role|password_hash|batch_id|force_pw_change
```

**db/batches.txt**
```
batch_id|admission_year|current_level|current_term|status
```

**db/courses.txt**
```
course_code|name|credits|level|term|type
```

**db/enrollments.txt**
```
username|batch_id|course_code|level|term|status
```

**db/teacher_courses.txt**
```
teacher_username|course_code
```

**courses/<code>/grades.txt**
```
username|batch_id|grade|gpa_points|timestamp
```

### Curriculum
The full CUET CSE 8-semester curriculum (Level 1–4, Term 1–2) is pre-defined in `setup/curriculum.sh`. It is loaded automatically when running with `--demo`, or can be loaded separately:

```bash
bash setup/curriculum.sh
```

### Batch Lifecycle
1. Admin creates a batch (e.g. `CSE2025`, starts at Level-1 Term-1)
2. Admin auto-enrolls the batch — all students get enrolled in all courses for that semester
3. Teachers enter grades
4. Admin advances the batch to the next semester — previous enrollments are locked as `completed`
5. Repeat until Level-4 Term-2, then mark as graduated

---

## Resetting Data

To start fresh, delete the generated directories:

```bash
rm -rf db/ courses/ logs/
```

Then re-run `bash main.sh` or `bash main.sh --demo`.

---

*Built for CSE 336 — Operating Systems Sessional, CUET*
