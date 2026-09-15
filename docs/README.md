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

## Concepts Explained

This section goes beyond *what* the scripts do, into *why* each technique 
was chosen — the reasoning a reader would need to actually understand and 
extend this project, not just run it.

### Why system checks are built the way they are
Getting a number like "disk usage" isn't a single command — it's a small 
pipeline: `df -h /` prints a full table of disk stats, but only one column 
(usage percentage) is needed, and only one row (the root filesystem). 
`grep '/'` narrows to the right row, `awk '{print $5}'` pulls out just the 
5th column, and `sed 's/%//'` strips the `%` sign so the result is a plain 
number Bash can do math and comparisons on. Each tool in that chain does 
one narrow job; chaining several single-purpose tools together with pipes 
(`|`) is a core Unix philosophy, and it's *why* the pipeline looks like 
several short commands stacked together rather than one big one.

Memory usage works differently because `free -m` doesn't give a ready-made 
percentage — it gives raw totals (total memory, used memory, in megabytes). 
The percentage has to be calculated manually with arithmetic expansion: 
`$(( (USED_MEM * 100) / TOTAL_MEM ))`. This is a different Bash construct 
from `$( ... )` (command substitution, used to *capture command output*) — 
`$(( ... ))` with double parentheses tells Bash "do math here," not "run a 
command here." Mixing these up is a common source of confusion, since they 
look almost identical.

### Why conditionals use `-ge`, not `>`
Inside `[ ... ]` test brackets, Bash reserves `>` and `<` for a different 
purpose (comparing text/strings alphabetically, or redirecting output to a 
file) — they do **not** mean "greater than" numerically in this context. 
For actual number comparisons, Bash test syntax uses word-based operators 
instead: `-ge` (greater than or equal), `-le` (less than or equal), `-eq` 
(equal), `-ne` (not equal), `-gt`, `-lt`. Using `>` where `-ge` was intended 
would silently do the wrong thing rather than error — another example of 
why defensive settings like `set -u` matter: not every mistake in Bash 
announces itself loudly on its own.

### Why exit codes matter beyond just this project
Every command run in a terminal leaves behind a numeric exit code: `0` 
always means success; any nonzero value (commonly `1`–`255`) means some 
kind of failure, with the specific number sometimes indicating *what kind* 
of failure occurred. This project uses exit codes deliberately — 
`health_monitor.sh` calling `exit 1` when a threshold is breached isn't 
just for a human reading the output; it's so that *other automation* 
(a CI/CD pipeline, a cron job, a monitoring system) calling this script can 
programmatically detect success or failure by checking `$?` immediately 
after the script runs, without needing to parse any text output at all. 
This is the exact mechanism real infrastructure automation relies on to 
decide whether to proceed, retry, or alert someone.

### Why functions use `return`, not `exit`, internally
These two are easy to conflate but behave very differently. `exit` 
terminates the *entire script* immediately, wherever it's called from. 
`return` only ends the *current function call*, handing a status code back 
to whatever called it, while the rest of the script keeps running normally. 
`check_threshold()` uses `return` specifically so that a single failed 
check (say, high disk usage) doesn't prevent the memory and process checks 
further down the script from running — all three checks are meant to be 
independent, so one failing shouldn't block the others from reporting.

### Why `local` matters for variable scoping
By default, any variable set inside a Bash function is **global** — visible 
and overwritable from anywhere else in the script, including other 
functions. This becomes dangerous quickly: if two functions both happen to 
use a variable named, say, `count`, one function's internal logic could 
silently corrupt the other's data with no warning. Declaring a variable 
`local` inside a function restricts its existence to that function alone — 
it's created fresh each time the function runs and disappears when the 
function returns. This is what makes a function genuinely reusable and 
safe to call multiple times (as `check_threshold()` is called three times 
in this project) without one call's internal state leaking into another's.

### Why `set -e`, `set -u`, and `set -o pipefail` are used together
Each flag closes a different gap in Bash's default (permissive) behavior:
- **`set -e`** stops the script the instant any command fails, instead of 
  Bash's default of continuing on to the next line as if nothing happened. 
  Without it, a failed `cd` into a wrong directory could be followed by 
  destructive commands still running — just in the wrong place.
- **`set -u`** turns any reference to an undefined variable into an 
  immediate error, rather than Bash's default of silently treating it as 
  an empty string. This project hit this directly: a typo (`home` instead 
  of `$HOME`) would otherwise have caused paths to quietly resolve 
  incorrectly instead of failing loudly and immediately at the source.
- **`set -o pipefail`** closes a specific gap in how pipelines report 
  status: normally, `cmd1 | cmd2 | cmd3` only reports whether the *last* 
  command succeeded, even if an earlier command in the chain secretly 
  failed. `pipefail` makes the whole pipeline fail if any part of it does.

Used together, these three flags shift a script's default behavior from 
"keep going and hope for the best" to "stop immediately and loudly at the 
first sign of a real problem" — which is the entire philosophy behind 
defensive scripting.

### Why `trap` is used for cleanup
`trap cleanup EXIT` registers a function to run automatically whenever the 
script exits — for *any* reason: finishing normally, hitting an error under 
`set -e`, or being interrupted (e.g. Ctrl+C). This matters because relying 
on cleanup code placed at the literal end of a script only works if the 
script actually reaches that final line — under `set -e`, a script can 
exit early from any point, potentially skipping cleanup entirely if it 
weren't registered as a trap. This is the same pattern real-world scripts 
use to guarantee temporary files get removed, locks get released, or 
completion gets logged, no matter how or where the script actually stops.

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
