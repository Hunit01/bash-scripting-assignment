#!/bin/bash

# ---------------------------------------------------------------
# user_setup.sh
# Author: Shreshth
# Student ID: 12345678
# Last Updated: 29 May 2025
# Description:
#   Automates user creation, group assignment, shared folder setup,
#   and symbolic link creation in a Dockerized Ubuntu environment.
# ---------------------------------------------------------------

# Define the log file path
LOG_FILE="/var/log/user_script.log"

# Define the base task directory for shared folder creation
TASK_DIR="/assignment1/task1"

# Create log file if it doesn't already exist
touch "$LOG_FILE"

# Prompt user for CSV file path or URL
echo "Enter the path or URL of the CSV file:"
read csv_input

# Check if the CSV is a remote URL
if [[ "$csv_input" == http* ]]; then
    csv_file="/tmp/users.csv"
    curl -s -o "$csv_file" "$csv_input"
    echo "$(date '+%F %T') Downloaded remote CSV to $csv_file" | tee -a "$LOG_FILE"
else
    csv_file="$csv_input"
    echo "$(date '+%F %T') Using local CSV file: $csv_file" | tee -a "$LOG_FILE"
fi

# Exit if CSV file doesn't exist
if [ ! -f "$csv_file" ]; then
    echo "$(date '+%F %T') Error: CSV file not found!" | tee -a "$LOG_FILE"
    exit 1
fi

# Read the CSV file line-by-line, skipping the header
tail -n +2 "$csv_file" | while IFS=',' read -r email birthdate groups sharedFolder; do

    # Extract username from email address (before @ symbol)
    username=$(echo "$email" | cut -d'@' -f1)

    # Generate password in MMYYYY format from birthdate
    password=$(date -d "$birthdate" +%m%Y 2>/dev/null)

    # Skip processing if username or password is missing
    if [ -z "$username" ] || [ -z "$password" ]; then
        echo "$(date '+%F %T') Skipping invalid entry: $email" | tee -a "$LOG_FILE"
        continue
    fi

    # Check if user already exists
    if id "$username" &>/dev/null; then
        echo "$(date '+%F %T') User $username already exists. Skipping..." | tee -a "$LOG_FILE"
    else
        # Create user and assign default password
        useradd -m "$username"
        echo "$username:$password" | chpasswd
        echo "$(date '+%F %T') Created user: $username with password: $password" | tee -a "$LOG_FILE"
    fi

    # Process and create groups
    IFS=';' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        if [ -n "$group" ]; then
            # Create group if it doesn't exist
            if ! getent group "$group" > /dev/null; then
                groupadd "$group"
                echo "$(date '+%F %T') Created group: $group" | tee -a "$LOG_FILE"
            fi
            # Add user to group
            usermod -aG "$group" "$username"
            echo "$(date '+%F %T') Added $username to group: $group" | tee -a "$LOG_FILE"
        fi
    done

    # Define full path for the shared folder
    shared_path="$TASK_DIR$sharedFolder"

    # Create shared folder and set correct group ownership and permissions
    mkdir -p "$shared_path"
    chown :${group_array[0]} "$shared_path"
    chmod 770 "$shared_path"
    echo "$(date '+%F %T') Shared folder created: $shared_path with group ${group_array[0]}" | tee -a "$LOG_FILE"

    # Create symlink in user's home directory if it doesn't already exist
    symlink_path="/home/$username/shared"
    if [ -L "$symlink_path" ]; then
        echo "$(date '+%F %T') Symlink already exists for $username. Skipping symlink creation." | tee -a "$LOG_FILE"
    else
        ln -s "$shared_path" "$symlink_path"
        echo "$(date '+%F %T') Created symlink in /home/$username/shared -> $shared_path" | tee -a "$LOG_FILE"
    fi

done

