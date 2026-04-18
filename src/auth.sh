#!/bin/bash
# auth.sh — Login, logout, session management, first-run setup

# SESSION_USERNAME / SESSION_ROLE / SESSION_FULLNAME / SESSION_BATCH
# are exported as env vars while a user is active (no temp files needed).
SESSION_USERNAME=""
SESSION_FULLNAME=""
SESSION_ROLE=""
SESSION_BATCH=""

# ── Session ───────────────────────────────────────────────────────────────────

_set_session() {
    SESSION_USERNAME="$1"
    SESSION_FULLNAME="$2"
    SESSION_ROLE="$3"
    SESSION_BATCH="$4"
}

clear_session() {
    SESSION_USERNAME=""
    SESSION_FULLNAME=""
    SESSION_ROLE=""
    SESSION_BATCH=""
}

# ── Login ─────────────────────────────────────────────────────────────────────

do_login() {
    print_header
    print_section "🔐 Login"
    echo ""
    read -rp "  Username : " uname
    read -rsp "  Password : " upass
    echo ""

    if [[ -z "$uname" || -z "$upass" ]]; then
        print_error "Username and password are required."
        pause; return 1
    fi

    if ! user_exists "$uname"; then
        local reg_status=""
        if [[ -f "$REGISTRATIONS_FILE" ]]; then
            reg_status=$(awk -F'|' -v u="$uname" '$1 == u {print $6; exit}' "$REGISTRATIONS_FILE")
        fi
        
        if [[ "$reg_status" == "pending" ]]; then
            print_info "Your account is currently under review by an administrator."
            pause; return 1
        elif [[ "$reg_status" == "rejected" ]]; then
            print_error "Your registration was rejected by an administrator."
            pause; return 1
        fi
        
        print_error "Invalid credentials."
        pause; return 1
    fi

    local stored_hash input_hash
    stored_hash=$(get_user_field "$uname" 4)
    input_hash=$(hash_password "$upass")

    if [[ "$stored_hash" != "$input_hash" ]]; then
        print_error "Invalid credentials."
        pause; return 1
    fi

    local role fullname batch force_pw
    fullname=$(get_user_field "$uname" 2)
    role=$(get_user_field "$uname" 3)
    batch=$(get_user_field "$uname" 5)
    force_pw=$(get_user_field "$uname" 6)

    _set_session "$uname" "$fullname" "$role" "$batch"
    log_action "$uname" "LOGIN"

    echo ""
    print_success "👋  Welcome, $fullname!"
    sleep 1

    # Force password change on first login
    if [[ "$force_pw" == "1" ]]; then
        _force_change_password "$uname"
    fi

    return 0
}

do_logout() {
    log_action "$SESSION_USERNAME" "LOGOUT"
    clear_session
}

# ── Password management ───────────────────────────────────────────────────────

_force_change_password() {
    local uname="$1"
    print_header
    print_section "🔑 First Login — Password Change Required"
    echo ""
    echo "  You must set a new password before continuing."
    echo ""
    _do_set_password "$uname"
}

change_password() {
    local uname="$1"
    print_header
    print_section "🔑 Change Password"
    echo ""

    local cur_pass cur_hash stored_hash
    read -rsp "  Current Password : " cur_pass; echo ""
    cur_hash=$(hash_password "$cur_pass")
    stored_hash=$(get_user_field "$uname" 4)

    if [[ "$cur_hash" != "$stored_hash" ]]; then
        print_error "Current password is incorrect."
        pause; return 1
    fi

    _do_set_password "$uname"
}

_do_set_password() {
    local uname="$1"
    local new_pass confirm_pass new_hash

    while true; do
        read -rsp "  New Password     : " new_pass;     echo ""
        read -rsp "  Confirm Password : " confirm_pass; echo ""

        if [[ "$new_pass" != "$confirm_pass" ]]; then
            print_error "Passwords do not match. Try again."
            continue
        fi
        if [[ ${#new_pass} -lt 6 ]]; then
            print_error "Password must be at least 6 characters."
            continue
        fi
        break
    done

    new_hash=$(hash_password "$new_pass")

    # Update hash and clear force_pw_change flag (field 4 and 6)
    local tmp; tmp=$(mktemp)
    awk -F'|' -v u="$uname" -v nh="$new_hash" 'BEGIN{OFS="|"} {
        if ($1 == u) { $4 = nh; $6 = "0" }
        print
    }' "$USERS_FILE" > "$tmp"
    mv "$tmp" "$USERS_FILE"

    log_action "$uname" "PASSWORD_CHANGED"
    echo ""
    print_success "Password changed successfully!"
    pause
}

# ── First-run setup ───────────────────────────────────────────────────────────

first_run_setup() {
    print_header
    echo "  🚀  FIRST TIME SETUP"
    echo ""
    echo "  No admin account found."
    echo "  Please create the initial administrator account."
    echo "$DIV"
    echo ""

    local uname fullname password confirm_pass password_hash

    # Username
    while true; do
        read -rp "  Admin Username : " uname
        uname=$(trim "$uname")
        if [[ -z "$uname" ]]; then
            print_error "Username cannot be empty."; continue
        fi
        if [[ ! "$uname" =~ ^[a-zA-Z0-9_]+$ ]]; then
            print_error "Only letters, numbers, and underscores allowed."; continue
        fi
        if user_exists "$uname"; then
            print_error "Username already taken."; continue
        fi
        break
    done

    # Full name
    while true; do
        read -rp "  Full Name      : " fullname
        fullname=$(trim "$fullname")
        [[ -n "$fullname" ]] && break
        print_error "Full name cannot be empty."
    done

    # Password
    while true; do
        read -rsp "  Password       : " password;      echo ""
        read -rsp "  Confirm        : " confirm_pass;  echo ""
        if [[ "$password" != "$confirm_pass" ]]; then
            print_error "Passwords do not match."; continue
        fi
        if [[ ${#password} -lt 6 ]]; then
            print_error "Password must be at least 6 characters."; continue
        fi
        break
    done

    password_hash=$(hash_password "$password")
    # fields: username|fullname|role|password_hash|batch_id|force_pw_change
    echo "${uname}|${fullname}|admin|${password_hash}||0" >> "$USERS_FILE"

    log_action "system" "FIRST_RUN_ADMIN_CREATED:${uname}"
    echo ""
    print_success "Admin account '${uname}' created!"
    echo "  You can now log in."
    pause
}

# ── Student Registration ──────────────────────────────────────────────────────

student_registration() {
    print_header
    print_section "📝 Student Registration"
    echo ""
    echo "  Please provide your details. Once submitted,"
    echo "  an administrator will review and approve your account."
    echo "$DIV"
    echo ""

    local uname fullname batch_id password confirm_pass password_hash trx_id

    # Username
    while true; do
        read -rp "  Desired Username : " uname
        uname=$(trim "$uname")
        if [[ -z "$uname" ]]; then print_error "Username cannot be empty."; continue; fi
        if [[ ! "$uname" =~ ^[a-zA-Z0-9_]+$ ]]; then
            print_error "Only letters, numbers, and underscores allowed."; continue
        fi
        if user_exists "$uname"; then print_error "Username already taken."; continue; fi
        
        # Check if already pending
        if grep -q "^${uname}|" "$REGISTRATIONS_FILE" 2>/dev/null; then
            print_error "You already have a pending registration."; continue
        fi
        break
    done

    while true; do
        read -rp "  Full Name        : " fullname
        fullname=$(trim "$fullname")
        [[ -n "$fullname" ]] && break
        print_error "Full name cannot be empty."
    done

    # Select Batch
    echo ""
    print_info "Select your target batch:"
    if ! pick_batch; then return; fi
    batch_id="$PICKED_ID"

    # Password
    echo ""
    while true; do
        read -rsp "  Password       : " password;      echo ""
        read -rsp "  Confirm        : " confirm_pass;  echo ""
        if [[ "$password" != "$confirm_pass" ]]; then
            print_error "Passwords do not match."; continue
        fi
        if [[ ${#password} -lt 6 ]]; then
            print_error "Password must be at least 6 characters."; continue
        fi
        break
    done

    # Payment
    echo ""
    print_section "💳 Payment System"
    echo "  Registration fee is 500 BDT."
    echo "  Transaction ID must be exactly 10 characters,"
    echo "  comprising a mix of uppercase letters and numbers."
    echo ""
    while true; do
        read -rp "  Enter Transaction ID: " trx_id
        trx_id=$(trim "$trx_id")
        if [[ ! "$trx_id" =~ ^[A-Z0-9]{10}$ ]]; then
            print_error "Transaction ID must be exactly 10 characters (uppercase and numbers)."
            continue
        fi
        if ! [[ "$trx_id" =~ [A-Z] ]] || ! [[ "$trx_id" =~ [0-9] ]]; then
            print_error "Transaction ID must contain a mix of both letters and numbers."
            continue
        fi
        break
    done

    password_hash=$(hash_password "$password")
    local timestamp; timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # format: username|fullname|password_hash|batch_id|trx_id|status|timestamp
    echo "${uname}|${fullname}|${password_hash}|${batch_id}|${trx_id}|pending|${timestamp}" >> "$REGISTRATIONS_FILE"

    log_action "system" "NEW_REGISTRATION_SUBMITTED:${uname}"
    
    echo ""
    print_success "Registration submitted successfully!"
    print_info "Your transaction ID is $trx_id."
    print_info "Hold onto this ID. An admin will review your registration."
    pause
}
