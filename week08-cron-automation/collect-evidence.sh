#!/usr/bin/env bash
# CVNP1601 Week 08 — Evidence Collection Script (Linux/bash)
# Run from the week's portfolio folder (or pass that folder as $1).
# Saves output to evidence-report.txt in that same folder.
# Commit evidence-report.txt to your GitHub portfolio repo under week08-cron-automation/.
#
# HOW TO RUN:
#   cd week08-cron-automation/
#   bash collect-evidence.sh
#   # then commit the generated evidence-report.txt and push
#
# GOTCHA: with no $1 argument, WEEK_DIR defaults to the script's own directory.
# Keep this script inside week08-cron-automation/ and run it from there so it
# scans the right folder for your required files.
#
# Kept intentionally close to plain POSIX shell (array use is the one
# bash-only feature) so it behaves the same on any Linux student VM.

set -uo pipefail
# NOTE: -e is deliberately NOT set. Several checks below (crontab -l with no
# crontab installed, /var/log/syslog missing on journald-only hosts) are
# expected to return non-zero without the whole report aborting — each such
# call is guarded with an explicit if/else so failures are reported inline
# instead of killing the script.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# Week folder defaults to this script's own directory, but can be overridden by
# passing a path as the first argument — useful for testing against a scratch folder.
WEEK_DIR="${1:-$SCRIPT_DIR}"
OUT_FILE="$WEEK_DIR/evidence-report.txt"

lines=()
lines+=("=== CVNP1601-W08 Evidence Report ===")
lines+=("Generated : $(date '+%Y-%m-%d %H:%M:%S')")
lines+=("Host      : $(hostname 2>/dev/null || uname -n)")
lines+=("Week      : 08")
lines+=("Folder    : $WEEK_DIR")
lines+=("")

# ── Crontab entries ───────────────────────────────────────────────────────────
# Proves Task 2/Task 5: the disk report job is scheduled with the final
# (not test) schedule and absolute paths.
lines+=("[CRONTAB ENTRIES — crontab -l]")
if output=$(crontab -l 2>&1); then
    while IFS= read -r l; do lines+=("  $l"); done <<< "$output"
else
    lines+=("  crontab -l failed or no crontab installed for this user: $output")
fi
lines+=("")

# ── Script presence and permissions ───────────────────────────────────────────
# Proves Task 1: disk_report.sh exists and is executable.
lines+=("[DISK REPORT SCRIPT — ls -la ~/scripts/disk_report.sh]")
if [ -e "$HOME/scripts/disk_report.sh" ]; then
    lines+=("  $(ls -la "$HOME/scripts/disk_report.sh" 2>&1)")
else
    lines+=("  $HOME/scripts/disk_report.sh not present on this host")
fi
lines+=("")

# ── Recent cron/log activity ──────────────────────────────────────────────────
# Proves Task 3: the script's own log AND an independent source (syslog or
# journalctl) both show the job actually ran, not just that it was scheduled.
lines+=("[RECENT CRON LOG ACTIVITY]")
for p in "$HOME/logs/disk_report.log" "$HOME/logs/disk_report_cron.log"; do
    if [ -f "$p" ]; then
        lines+=("  --- tail -5 $p ---")
        while IFS= read -r l; do lines+=("    $l"); done < <(tail -5 "$p" 2>&1)
    else
        lines+=("  $p not present on this host")
    fi
done
if output=$(grep CRON /var/log/syslog 2>/dev/null | tail -5); then
    if [ -n "$output" ]; then
        lines+=("  --- grep CRON /var/log/syslog | tail -5 ---")
        while IFS= read -r l; do lines+=("    $l"); done <<< "$output"
    else
        lines+=("  /var/log/syslog present but no CRON entries found — try: sudo journalctl -u cron.service")
    fi
else
    lines+=("  /var/log/syslog not available on this host — try: sudo journalctl -u cron.service")
fi
lines+=("")

# ── Required files ────────────────────────────────────────────────────────────
# Every deliverable the Week 08 assignment requires. Keep this array in sync
# with the assignment's Submission Checklist.
lines+=("[REQUIRED FILES]")
REQUIRED_FILES=(
    "README.md"
    "week1-cheatsheet.txt"
    "disk_report.sh"
    "cron-troubleshooting-note.md"
    "tech-lead-note.md"
    "troubleshooting-narrative.md"
    "week8-diagnosis.md"
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

lines+=("Commit this file (evidence-report.txt) to your GitHub repo under week08-cron-automation/.")

printf '%s\n' "${lines[@]}" >"$OUT_FILE"
printf '%s\n' "${lines[@]}"
