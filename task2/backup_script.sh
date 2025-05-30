#!/bin/bash

# -------------------------------------------------------------
# backup_script.sh
# Author:Hunit
# Last Updated: 29 May 2025
# Description:
#   Takes input from the user for source and destination folders,
#   creates a compressed archive of the source, stores it in the
#   destination, and logs the actions.
# -------------------------------------------------------------

# Define log file
LOG_FILE="/var/log/backup_script.log"
touch "$LOG_FILE"

# Prompt for source directory
echo "Enter the full path of the directory you want to back up:"
read source_dir

# Validate the source directory
if [ ! -d "$source_dir" ]; then
    echo "Error: Directory '$source_dir' does not exist!"
    echo "$(date '+%F %T') [ERROR] Source directory not found: $source_dir" >> "$LOG_FILE"
    exit 1
fi

# Prompt for destination directory
echo "Enter the directory where the backup should be stored:"
read backup_dir

# Create destination if it doesn't exist
mkdir -p "$backup_dir"

# Get base name of source folder
dir_name=$(basename "$source_dir")

# Create archive name with timestamp
timestamp=$(date +%Y%m%d%H%M%S)
archive_name="${dir_name}_backup_${timestamp}.tar.gz"

# Create compressed archive
tar -czf "$archive_name" "$source_dir" 2>> "$LOG_FILE"

# Move archive to destination
mv "$archive_name" "$backup_dir"

# Log and confirm
echo "$(date '+%F %T') [INFO] Backup created: $archive_name from $source_dir to $backup_dir" >> "$LOG_FILE"
echo "Backup completed successfully."
echo "Archive stored at: $backup_dir/$archive_name"
