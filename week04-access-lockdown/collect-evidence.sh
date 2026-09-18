#!/usr/bin/env bash
# CVNP1601 Week 04 — Evidence Collection Script (Linux/bash)
# Run from the week's portfolio folder (or pass that folder as $1).
# Saves output to evidence-report.txt in that same folder.
# Commit evidence-report.txt to your GitHub portfolio repo under week04-access-lockdown/.
#
# HOW TO RUN:
#   cd week04-access-lockdown/
#   bash collect-evidence.sh
#   # then commit the generated evidence-report.txt and push
#
# GOTCHA: with no $1 argument, WEEK_DIR defaults to the script's own directory.
# Keep this script inside week04-access-lockdown/ and run it from there so it
# scans the right folder for your required files.
#
# Kept intentionally close to plain POSIX shell (array use is the one
# bash-only feature) so it behaves the same on any Linux student VM.

set -uo pipefail
# NOTE: -e is deliberately NOT set. Several checks below (a path that may not
# exist on a given VM, grep with no match) are expected to return non-zero
# without the whole report aborting — each such call is guarded with an
# explicit if/else so failures are reported inline instead of killing the
# script.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# Week folder defaults to this script's own directory, but can be overridden by
# passing a path as the first argument — useful for testing against a scratch folder.
WEEK_DIR="${1:-$SCRIPT_DIR}"
OUT_FILE="$WEEK_DIR/evidence-report.txt"

lines=()
lines+=("=== CVNP1601-W04 Evidence Report ===")
lines+=("Generated : $(date '+%Y-%m-%d %H:%M:%S')")
lines+=("Host      : $(hostname 2>/dev/null || uname -n)")
lines+=("Week      : 04")
lines+=("Folder    : $WEEK_DIR")
lines+=("")

# ── /project permission state ─────────────────────────────────────────────────
# Proves Tasks 2-4: chmod/chown, sticky bit, and SGID configuration on /project.
lines+=("[/PROJECT PERMISSION STATE — ls -ld /project]")
if [ -e /project ]; then
    lines+=("  $(ls -ld /project 2>&1)")
else
    lines+=("  /project not present on this host")
fi
lines+=("")

# ── /project ACL state ────────────────────────────────────────────────────────
# Proves Task 5: getfacl output showing named-user/group ACL entries.
lines+=("[/PROJECT ACL STATE — getfacl /project]")
if [ -e /project ]; then
    if output=$(getfacl /project 2>&1); then
        while IFS= read -r l; do lines+=("  $l"); done <<< "$output"
    else
        lines+=("  getfacl not available or failed: $output")
    fi
else
    lines+=("  /project not present on this host")
fi
lines+=("")

# ── umask ─────────────────────────────────────────────────────────────────────
# Proves Task 1: current default-permission policy for new files.
lines+=("[CURRENT UMASK]")
lines+=("  $(umask)")
lines+=("")

# ── Required files ────────────────────────────────────────────────────────────
# Every deliverable the Week 04 assignment requires. Keep this array in sync
# with the assignment's Submission Checklist.
lines+=("[REQUIRED FILES]")
REQUIRED_FILES=(
    "README.md"
    "permission-audit.txt"
    "acl-audit.txt"
    "tech-lead-note.md"
    "troubleshooting-narrative.md"
    "week4-diagnosis.md"
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

lines+=("Commit this file (evidence-report.txt) to your GitHub repo under week04-access-lockdown/.")

printf '%s\n' "${lines[@]}" >"$OUT_FILE"
printf '%s\n' "${lines[@]}"
