#!/usr/bin/env bash
# CVNP1601 Week 11 — Evidence Collection Script (Linux/bash)
# Run from the week's portfolio folder (or pass that folder as $1).
# Saves output to evidence-report.txt in that same folder.
# Commit evidence-report.txt to your GitHub portfolio repo under week11-ssh-log-analysis/.
#
# HOW TO RUN:
#   cd week11-ssh-log-analysis/
#   bash collect-evidence.sh
#   # then commit the generated evidence-report.txt and push
#
# GOTCHA: with no $1 argument, WEEK_DIR defaults to the script's own directory.
# Keep this script inside week11-ssh-log-analysis/ and run it from there so it
# scans the right folder for your required files.
#
# Kept intentionally close to plain POSIX shell (array use is the one
# bash-only feature) so it behaves the same on any Linux student VM.

set -uo pipefail
# NOTE: -e is deliberately NOT set. Several checks below (auth.log missing on
# a journald-only system, sudo prompting non-interactively) are expected to
# return non-zero without the whole report aborting — each such call is
# guarded with an explicit if/else so failures are reported inline instead of
# killing the script.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# Week folder defaults to this script's own directory, but can be overridden by
# passing a path as the first argument — useful for testing against a scratch folder.
WEEK_DIR="${1:-$SCRIPT_DIR}"
OUT_FILE="$WEEK_DIR/evidence-report.txt"

lines=()
lines+=("=== CVNP1601-W11 Evidence Report ===")
lines+=("Generated : $(date '+%Y-%m-%d %H:%M:%S')")
lines+=("Host      : $(hostname 2>/dev/null || uname -n)")
lines+=("Week      : 11")
lines+=("Folder    : $WEEK_DIR")
lines+=("")

# ── Log source availability ───────────────────────────────────────────────────
# Proves Task 1: confirms which SSH log source(s) exist on this system before
# any pipeline evidence is trusted.
lines+=("[LOG SOURCE — auth.log presence]")
if [ -f /var/log/auth.log ]; then
    size=$(wc -c </var/log/auth.log 2>/dev/null | tr -d ' ')
    lines+=("  /var/log/auth.log present ($size bytes)")
else
    lines+=("  /var/log/auth.log NOT present on this host — journalctl is the only source (document this in your report)")
fi
lines+=("")

# ── SSH journal unit check ────────────────────────────────────────────────────
# Proves Task 1: confirms whether the ssh or sshd unit name is correct on this
# host, and that journalctl returns entries at all.
lines+=("[SSH JOURNAL UNIT — journalctl -u ssh/sshd]")
if output=$(journalctl -u ssh --no-pager -n 5 2>&1) && [ -n "$output" ]; then
    lines+=("  unit 'ssh' returned entries:")
    while IFS= read -r l; do lines+=("    $l"); done <<< "$output"
elif output=$(journalctl -u sshd --no-pager -n 5 2>&1) && [ -n "$output" ]; then
    lines+=("  unit 'sshd' returned entries:")
    while IFS= read -r l; do lines+=("    $l"); done <<< "$output"
else
    lines+=("  Neither 'ssh' nor 'sshd' unit returned journal entries: $output")
fi
lines+=("")

# ── Failed-password count sanity check ────────────────────────────────────────
# Proves Task 2/4: a live count independent of the student's own screenshots,
# used as a spot-check during grading (not a substitute for reviewing the
# student's actual pipeline evidence).
lines+=("[FAILED PASSWORD COUNT — live sanity check]")
if [ -r /var/log/auth.log ]; then
    count=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null || echo "0")
    lines+=("  grep -c \"Failed password\" /var/log/auth.log => $count")
else
    lines+=("  /var/log/auth.log not readable on this host — cannot run live sanity check")
fi
lines+=("")

# ── Required files ────────────────────────────────────────────────────────────
# Every deliverable the Week 11 assignment requires. Keep this array in sync
# with the assignment's Submission Checklist.
lines+=("[REQUIRED FILES]")
REQUIRED_FILES=(
    "README.md"
    "week1-cheatsheet.txt"
    "attack-summary.md"
    "tech-lead-note.md"
    "troubleshooting-narrative.md"
    "week11-diagnosis.md"
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

lines+=("Commit this file (evidence-report.txt) to your GitHub repo under week11-ssh-log-analysis/.")
lines+=("Screenshots of pipeline evidence are not checked above (binary/non-deterministic filenames) but are still required per the Submission Checklist.")

printf '%s\n' "${lines[@]}" >"$OUT_FILE"
printf '%s\n' "${lines[@]}"
