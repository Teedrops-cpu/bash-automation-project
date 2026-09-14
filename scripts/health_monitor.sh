#!/bin/bash
set -euo pipefail

# --- Cleanup trap ----
# This runs automatically whenever the script exits, for any reason -  normal  completion, an error, or the user pressing Ctrl+C.

cleanup() {
      echo "Health monitor script finished. Exit code: $?"
}
trap cleanup EXIT

# Task 3: System Health Monitor - refactored with functions
# Checks disk, memory, and process count against threshold using a reusable function.

# ---- Reusable threshold-check function ----
# Arguments: $1 =  label (what we're checking), $2 = current value, $3 = threshold
check_threshold() {
	local label="$1"
	local value="$2"
	local threshold="$3"

	echo "Current $label: ${value}%"

	if [ "$value" -ge "$threshold" ]; then
	     echo "Warning: $label is above threshold (${threshold}%)"
	     return 1
	else
	     echo "OK: $label is within safe limits"
	     return 0
	fi
}

# ---- Gather system data ----
DISK_USAGE=$(df -h / | grep '/' | awk '{print $5}' | sed 's/%//')

TOTAL_MEM=$(free -m | grep Mem | awk '{print $2}')
USED_MEM=$(free -m | grep Mem | awk '{print $3}')
MEM_USAGE=$(( (USED_MEM*100) / TOTAL_MEM ))
PROCESS_COUNT=$(ps aux | wc -l)

# ---- Run checks using the function ----
check_threshold "disk usage" "$DISK_USAGE" 80
check_threshold "memory usage" "$MEM_USAGE" 80


# Process count uses a different scale (raw count, not %), so we call it separately
echo "Current running process count: $PROCESS_COUNT"
if [ "$PROCESS_COUNT" -ge 300 ]; then
	echo "WARNING: Process count is unusally high"
else
	echo "OK: Process count is normal"
fi



echo "All health checks completed"
