#!/bin/bash

# Task 2: System Health Monitor
# Checks disk usage, memory usage, and reports status via exit codes.

# ---- Disk usage check ----
# df -h / shows disk usage for root filesystem in human-readable form
# we grab just the usage percentage number using a pipeline of tools:
DISK_USAGE=$(df -h / | grep '/' | awk '{print $5}' | sed 's/%//')

DISK_THRESHOLD=80

echo "Current disk usage: ${DISK_USAGE}%"

if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
   echo "WARNING: Disk usage is above threshold (${DISK_THRESHOLD}%)"
   exit 1
else
   echo "OK: Disk usage is within safe limits"
fi


# ---- Memory usage check ----
# free -m shows memory in megabytes; the second line has the actual numbers
# Column 2 = total memory, Column 3 = used memory
TOTAL_MEM=$(free -m | grep Mem | awk '{print $2}')
USED_MEM=$(free -m | grep Mem | awk '{print $3}')

# Calculate percentage used (integer math using bash arithmetic expansion)
MEM_USAGE=$(( (USED_MEM * 100) / TOTAL_MEM ))
MEM_THRESHOLD=80

echo "Current memory usage: ${MEM_USAGE}%"

if [ "$MEM_USAGE" -ge "$MEM_THRESHOLD" ]; then
   echo "Warning: Memory usage is above threshold (${MEM_THRESHOLD}%)"
   exit 1
else
   echo "OK: Memory usage is withing safe limits"
fi


# ---- Process count check ----
# ps aux lists all running processes; wc -1 counts the lines
PROCESS_COUNT=$(ps aux | wc -l)
PROCESS_THRESHOLD=300

echo "Current running process count: $PROCESS_COUNT"

if [ "$PROCESS_COUNT" -ge "$PROCESS_THRESHOLD" ]; then
   echo "WARNING: Process count is unusually high (${PROCESS_THRESHOLD}+)"
   exit 1
else
   echo "OK: Process count is normal"
fi

echo "ALL health checks passed."
exit 0

