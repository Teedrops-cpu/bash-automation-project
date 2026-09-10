#~/bin/bash

# Task 1: Automate Directory and File Creation
# This script creates a nested directory structure with dynamic files.

# Capture the current timestamps for unique, traceable naming
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Define the base project directory
BASE_DIR="$HOME/bash-automation-project/generated"

echo "Timestamp is: $TIMESTAMP"
echo "Base directory will be: $BASE_DIR"

# Create nested directory structure idempotently
# mkdir -p won't error if directories already exist, and creates parent as needed

mkdir -p "$BASE_DIR/logs"
mkdir -p "$BASE_DIR/config"
mkdir -p "$BASE_DIR/data"

echo "Directories created (or already existed) under $BASE_DIR"

# Creates a dynamically-named log file using the timestamp
LOG_FILE="$BASE_DIR/logs/run_$TIMESTAMP.log"

# Only create the file if it doesn't already exist (extra idempotency check)
if [ ! -f "$LOG_FILE" ]; then
   echo "Log created on $(date)" > "$LOG_FILE"
   echo "Created new log file: $LOG_FILE"
else
   echo "Log file already exists: $LOG_FILE"
fi

# Create a static config file only if missing - this one should NOT be overwritten on rerun
CONFIG_FILE="$BASE_DIR/config/settings.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "environment=development" > "$CONFIG_FILE"
    echo "Created config file: $CONFIG_FILE"
else
    echo "Config file already exists, leaving untouched: $CONFIG_FIEL"
fi

