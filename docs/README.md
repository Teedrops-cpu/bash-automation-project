# Bash Task Automation — Project README

## Overview
This project is a hands-on introduction to Bash scripting for DevOps 
automation. It covers idempotent file/directory creation, system health 
monitoring, modular functions, and defensive scripting practices 
(input validation, error handling, and cleanup via `trap`).

## Project Structure
```
bash-automation-project/
├── scripts/
│   ├── create_structure.sh   # Task 1 & 4: Idempotent structure creation + input validation
│   ├── health_monitor.sh     # Task 2 & 3 & 4: System health checks, refactored into functions
│   └── function_demo.sh      # Task 3: Standalone demo of Bash function syntax and scoping
├── docs/
│   └── README.md             # This file
├── screenshots/              # Evidence of successful execution and debugging
└── generated/                # Runtime output (ignored by Git — see .gitignore)
```

## Scripts and Logic

### 1. `create_structure.sh` — Directory & File Automation (Task 1 & 4)
**What it does:** Creates a nested directory structure (`logs/`, `config/`, 
`data/`) under a base directory, along with a timestamped log file and a 
persistent config file.

**Key logic:**
- `TIMESTAMP=$(date +"%Y%m%d_%H%M%S")` — captures the current date/time via 
  command substitution, used to generate unique filenames.
- `mkdir -p` — creates the full directory tree in one command; safe to 
  re-run since it doesn't error on existing directories.
- **Idempotency is handled differently per file type:**
  - The **log file** is always newly created each run (its name includes 
    the timestamp, so each run produces a distinct file — this is 
    intentional, since logs should represent individual runs).
  - The **config file** is only created if it doesn't already exist 
    (`if [ ! -f "$CONFIG_FILE" ]`) — reruns will not overwrite existing 
    configuration.
- **Input validation (Task 4):** the script accepts an optional custom 
  target directory as its first argument (`${1:-$HOME/bash-automation-project/generated}`). 
  Before using it, the script checks that the *parent* of that path 
  actually exists (`dirname`) and exits with a clear error if not — 
  preventing the script from being pointed at garbage input.
- **Safety flags:** `set -euo pipefail` at the top ensures the script stops 
  immediately on any command failure, undefined variable reference, or 
  broken pipeline, rather than continuing silently with bad state.

**Usage:**
```bash
# Use default location
bash scripts/create_structure.sh

# Use a custom location
bash scripts/create_structure.sh /path/to/custom/location
```

### 2. `health_monitor.sh` — System Health Monitor (Task 2, 3 & 4)
**What it does:** Checks disk usage, memory usage, and running process 
count against defined thresholds, reporting status for each.

**Key logic:**
- System data is gathered using standard Unix tools chained together with 
  pipes: `df`, `free`, and `ps`, filtered and extracted using `grep`, 
  `awk`, and `sed`.
- **Refactored into a reusable function (Task 3):** rather than repeating 
  the same "compare value to threshold, print OK/WARNING" logic three 
  times, that logic lives in one function, `check_threshold()`, called 
  once per metric with different arguments (`$1` = label, `$2` = value, 
  `$3` = threshold). Variables inside the function are declared `local`, 
  scoping them to the function only.
- `return` (not `exit`) is used inside the function, so one failed check 
  doesn't terminate the whole script before the remaining checks run.
- **Cleanup via `trap` (Task 4):** a `cleanup()` function is registered 
  with `trap cleanup EXIT`, so it runs automatically whenever the script 
  exits — whether it finishes normally, hits an error under `set -e`, or 
  is interrupted.

**Usage:**
```bash
bash scripts/health_monitor.sh
```

### 3. `function_demo.sh` — Function Syntax Demo (Task 3)
A minimal standalone script used to learn and confirm Bash function syntax 
(`function_name() { ... }`), argument passing via `$1`, and `local` 
variable scoping, before applying the same pattern to the real health 
monitor script.

## Results Achieved
- Both core scripts (`create_structure.sh`, `health_monitor.sh`) run 
  successfully and idempotently — verified by running each multiple times 
  with no errors or unwanted duplication.
- Input validation correctly rejects invalid paths (tested with a 
  deliberately fake path) while accepting valid ones.
- `set -u` was verified to correctly catch an unbound/undefined variable 
  reference during development — this caught several real typos 
  (a missing `$` before a variable name, and a variable name typo) before 
  they could cause silent, hard-to-trace bugs.
- Screenshots in `screenshots/` show both clean successful runs and the 
  actual debugging process for these issues.

## Notes on Debugging Process
Several real bugs were hit and fixed during development, each a useful 
example of common Bash pitfalls:
- **Missing `$` before a variable name** (e.g. `home` instead of `$HOME`) 
  — Bash silently treats this as literal text rather than a variable 
  reference, rather than throwing an error on its own; `set -u` surfaces 
  this as an "unbound variable" error once the mistyped name is actually 
  referenced elsewhere.
- **Case sensitivity** — `$HOME` and `$home` are entirely different 
  variables to Bash; only `HOME` (uppercase) is the real built-in variable.
- **`bash -x` (trace mode)** was used to debug by printing each command 
  with its actual substituted values at runtime, making it possible to see 
  exactly where a variable's value diverged from what was expected.

## Completion Checklist
- [x] Task 1: Idempotent directory/file creation script, using variables, 
      command substitution, and timestamps
- [x] Task 2: System health monitor using `df`, `free`, `ps`, conditionals, 
      and exit codes
- [x] Task 3: Logic refactored into a reusable function with argument 
      passing and `local` variable scoping
- [x] Task 4: `set -e`, `set -u`, `set -o pipefail` applied; input path 
      validation implemented; `trap`-based cleanup implemented
- [x] Task 5: Project organized into `scripts/`, `docs/`, `screenshots/`; 
      README documents logic and results; all work committed incrementally 
      to Git with descriptive messages
