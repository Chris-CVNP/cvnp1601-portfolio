#!/usr/bin/env bash
# CVNP1601 Week 06 — Evidence Collection Script (Linux/bash)
# Run from the week's portfolio folder (or pass that folder as $1).
# Saves output to evidence-report.txt in that same folder.
# Commit evidence-report.txt to your GitHub portfolio repo under week06-backup-script/.
#
# HOW TO RUN:
#   cd week06-backup-script/
#   bash collect-evidence.sh
#   # then commit the generated evidence-report.txt and push
#
# GOTCHA: with no $1 argument, WEEK_DIR defaults to the script's own directory.
# Keep this script inside week06-backup-script/ and run it from there so it
# scans the right folder for your required files.
#
# Kept intentionally close to plain POSIX shell (array use is the one
# bash-only feature) so it behaves the same on any Linux student VM.

set -uo pipefail
# NOTE: -e is deliberately NOT set. Several checks below (bash -n on a
# missing file, a git log query against a folder that isn't a repo) are
# expected to return non-zero without the whole report aborting — each such
# call is guarded with an explicit if/else so failures are reported inline
# instead of killing the script.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# Week folder defaults to this script's own directory, but can be overridden by
# passing a path as the first argument — useful for testing against a scratch folder.
WEEK_DIR="${1:-$SCRIPT_DIR}"
OUT_FILE="$WEEK_DIR/evidence-report.txt"

lines=()
lines+=("=== CVNP1601-W06 Evidence Report ===")
lines+=("Generated : $(date '+%Y-%m-%d %H:%M:%S')")
lines+=("Host      : $(hostname 2>/dev/null || uname -n)")
lines+=("Week      : 06")
lines+=("Folder    : $WEEK_DIR")
lines+=("")

# ── backup_etc.sh syntax check ────────────────────────────────────────────────
# Proves Task 1/2: the committed script at least parses as valid bash.
lines+=("[BACKUP_ETC.SH SYNTAX — bash -n]")
if [ -f "$WEEK_DIR/backup_etc.sh" ]; then
    if output=$(bash -n "$WEEK_DIR/backup_etc.sh" 2>&1); then
        lines+=("  Syntax OK")
    else
        lines+=("  Syntax error: $output")
    fi
else
    lines+=("  backup_etc.sh not found in $WEEK_DIR")
fi
lines+=("")

# ── backup_etc.sh permissions ─────────────────────────────────────────────────
# Proves Task 1: the script is executable.
lines+=("[BACKUP_ETC.SH PERMISSIONS — ls -la]")
if [ -f "$WEEK_DIR/backup_etc.sh" ]; then
    lines+=("  $(ls -la "$WEEK_DIR/backup_etc.sh" 2>&1)")
else
    lines+=("  backup_etc.sh not found in $WEEK_DIR")
fi
lines+=("")

# ── Git history in ~/scripts ───────────────────────────────────────────────────
# Proves Task 3: at least two meaningful commits exist in the Linux-side repo
# where the script was actually built (~/scripts, not this portfolio folder).
lines+=("[GIT LOG — ~/scripts]")
if [ -d "$HOME/scripts/.git" ]; then
    if output=$(git -C "$HOME/scripts" log --oneline 2>&1); then
        commit_count=$(printf '%s\n' "$output" | grep -c .)
        while IFS= read -r l; do lines+=("  $l"); done <<< "$output"
        lines+=("  Commit count: $commit_count")
    else
        lines+=("  git log failed: $output")
    fi
else
    lines+=("  No .git found at ~/scripts on this host — confirm your Git history separately in your evidence packet.")
fi
lines+=("")

# ── Required files ────────────────────────────────────────────────────────────
# Every deliverable the Week 06 assignment requires. Keep this array in sync
# with the assignment's Submission Checklist.
lines+=("[REQUIRED FILES]")
REQUIRED_FILES=(
    "README.md"
    "backup_etc.sh"
    "week1-cheatsheet.txt"
    "tech-lead-note.md"
    "troubleshooting-narrative.md"
    "week6-diagnosis.md"
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

lines+=("Commit this file (evidence-report.txt) to your GitHub repo under week06-backup-script/.")

printf '%s\n' "${lines[@]}" >"$OUT_FILE"
printf '%s\n' "${lines[@]}"
