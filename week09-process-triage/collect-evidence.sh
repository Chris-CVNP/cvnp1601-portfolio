#!/usr/bin/env bash
# CVNP1601 Week 09 — Evidence Collection Script (Linux/bash)
# Run from the week's portfolio folder (or pass that folder as $1).
# Saves output to evidence-report.txt in that same folder.
# Commit evidence-report.txt to your GitHub portfolio repo under week09-process-triage/.
#
# HOW TO RUN:
#   cd week09-process-triage/
#   bash collect-evidence.sh
#   # then commit the generated evidence-report.txt and push
#
# GOTCHA: with no $1 argument, WEEK_DIR defaults to the script's own directory.
# Keep this script inside week09-process-triage/ and run it from there so it
# scans the right folder for your required files.
#
# Kept intentionally close to plain POSIX shell (array use is the one
# bash-only feature) so it behaves the same on any Linux student VM.

set -uo pipefail
# NOTE: -e is deliberately NOT set. Several checks below (nginx not installed,
# insufficient privilege for journalctl) are expected to return non-zero
# without the whole report aborting — each such call is guarded with an
# explicit if/else so failures are reported inline instead of killing the
# script.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# Week folder defaults to this script's own directory, but can be overridden by
# passing a path as the first argument — useful for testing against a scratch folder.
WEEK_DIR="${1:-$SCRIPT_DIR}"
OUT_FILE="$WEEK_DIR/evidence-report.txt"

lines=()
lines+=("=== CVNP1601-W09 Evidence Report ===")
lines+=("Generated : $(date '+%Y-%m-%d %H:%M:%S')")
lines+=("Host      : $(hostname 2>/dev/null || uname -n)")
lines+=("Week      : 09")
lines+=("Folder    : $WEEK_DIR")
lines+=("")

# ── Process snapshot ──────────────────────────────────────────────────────────
# Proves Task 1: reading ps aux sorted by CPU usage to identify a process by
# PID, owner, and command before acting on it.
lines+=("[PROCESS SNAPSHOT — ps aux --sort=-%cpu (top 10)]")
if output=$(ps aux --sort=-%cpu 2>&1 | head -10); then
    while IFS= read -r l; do lines+=("  $l"); done <<< "$output"
else
    lines+=("  ps aux failed: $output")
fi
lines+=("")

# ── nginx service state ───────────────────────────────────────────────────────
# Proves Task 3/4: current active/enabled state of the service being diagnosed.
lines+=("[NGINX SERVICE STATE]")
if command -v systemctl >/dev/null 2>&1; then
    if output=$(systemctl is-active nginx 2>&1); then
        lines+=("  is-active : $output")
    else
        lines+=("  is-active : $output")
    fi
    if output=$(systemctl is-enabled nginx 2>&1); then
        lines+=("  is-enabled: $output")
    else
        lines+=("  is-enabled: $output")
    fi
else
    lines+=("  systemctl not available on this host")
fi
lines+=("")

# ── Recent nginx journal ───────────────────────────────────────────────────────
# Proves Task 3/4: journalctl evidence exists and --no-pager was used (a
# hanging pager here would mean the required flag was forgotten).
lines+=("[RECENT JOURNAL — journalctl -u nginx -n 20 --no-pager]")
if output=$(sudo journalctl -u nginx -n 20 --no-pager 2>&1); then
    while IFS= read -r l; do lines+=("  $l"); done <<< "$output"
else
    lines+=("  journalctl query failed or needs sudo on this host: $output")
fi
lines+=("")

# ── Required files ────────────────────────────────────────────────────────────
# Every deliverable the Week 09 assignment requires. Keep this array in sync
# with the assignment's Submission Checklist. The timestamped journal capture
# file from Task 4 is intentionally excluded — its filename is non-deterministic
# (embeds a date/time) so it cannot be checked by exact name here; confirm it
# manually during grading instead.
lines+=("[REQUIRED FILES]")
REQUIRED_FILES=(
    "README.md"
    "week1-cheatsheet.txt"
    "tech-lead-note.md"
    "troubleshooting-narrative.md"
    "incident-worklog.md"
    "week9-diagnosis.md"
)
for f in "${REQUIRED_FILES[@]}"; do
    p="$WEEK_DIR/$f"
    if [ -f "$p" ]; then
        size=$(wc -c <"$p" 2>/dev/null | tr -d ' ')
        lines+=("  $f : FOUND ($size bytes)")
    else
        lines+=("  $f : NOT FOUND")
    fi
done
lines+=("")

# ── Secret / credential leak scan ─────────────────────────────────────────────
# Best-effort warning pass over every file about to be committed. Not a
# substitute for reviewing your own submission — it catches the common,
# careless leaks (pasted tokens, private keys, literal passwords).
lines+=("[SECRET SCAN]")
SECRET_PATTERNS=(
    'BEGIN (RSA|OPENSSH|DSA|EC|PGP) PRIVATE KEY'  # private key material
    'AKIA[0-9A-Z]{16}'                            # AWS access key id
    'aws_secret_access_key'                       # AWS secret key
    'ghp_[0-9A-Za-z]{36}'                         # GitHub personal access token
    'gh[pousr]_[0-9A-Za-z]{20,}'                  # other GitHub token prefixes
    'xox[baprs]-[0-9A-Za-z-]+'                    # Slack token
    'password[[:space:]]*[:=][[:space:]]*[^[:space:]]+'
    'passwd[[:space:]]*[:=][[:space:]]*[^[:space:]]+'
    'secret[[:space:]]*[:=][[:space:]]*[^[:space:]]+'
    'api[_-]?key[[:space:]]*[:=][[:space:]]*[^[:space:]]+'
    'token[[:space:]]*[:=][[:space:]]*[^[:space:]]+'
)
secrets_found=0
for f in "$WEEK_DIR"/*; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    case "$base" in
        evidence-report.txt|collect-evidence.sh) continue ;;
    esac
    # Skip binaries/non-text files (screenshots, etc.) — grep -I self-detects.
    if ! grep -Iq . "$f" 2>/dev/null; then
        continue
    fi
    for pat in "${SECRET_PATTERNS[@]}"; do
        if grep -EIiq "$pat" "$f" 2>/dev/null; then
            lines+=("  WARNING: possible secret/token pattern found in $base — review before committing (pattern: $pat)")
            secrets_found=1
        fi
    done
done
if [ "$secrets_found" -eq 0 ]; then
    lines+=("  No obvious secret/token patterns detected. Still manually review every file before committing.")
fi
lines+=("")

lines+=("Commit this file (evidence-report.txt) to your GitHub repo under week09-process-triage/.")
lines+=("Remember to also commit your timestamped journalctl capture file from Task 4 — it is not")
lines+=("checked above because its filename includes a timestamp, but it is still required.")

printf '%s\n' "${lines[@]}" >"$OUT_FILE"
printf '%s\n' "${lines[@]}"
