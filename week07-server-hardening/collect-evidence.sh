#!/usr/bin/env bash
# CVNP1601 Week 07 — Evidence Collection Script (Linux/bash)
# Run from the week's portfolio folder (or pass that folder as $1).
# Saves output to evidence-report.txt in that same folder.
# Commit evidence-report.txt to your GitHub portfolio repo under week07-server-hardening/.
#
# HOW TO RUN:
#   cd week07-server-hardening/
#   bash collect-evidence.sh
#   # then commit the generated evidence-report.txt and push
#
# GOTCHA: with no $1 argument, WEEK_DIR defaults to the script's own directory.
# Keep this script inside week07-server-hardening/ and run it from there so it
# scans the right folder for your required files.
#
# SECURITY NOTE: this script only ever reads sshd's *effective configuration*
# (sudo sshd -T) and ufw/permission state — it never reads or copies private
# key material, and the secret scan below will warn if a private key ever
# ends up in this folder by mistake.
#
# Kept intentionally close to plain POSIX shell (array use is the one
# bash-only feature) so it behaves the same on any Linux student VM.

set -uo pipefail
# NOTE: -e is deliberately NOT set. Several checks below (sshd -T without
# root, ufw not installed) are expected to return non-zero without the whole
# report aborting — each such call is guarded with an explicit if/else so
# failures are reported inline instead of killing the script.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# Week folder defaults to this script's own directory, but can be overridden by
# passing a path as the first argument — useful for testing against a scratch folder.
WEEK_DIR="${1:-$SCRIPT_DIR}"
OUT_FILE="$WEEK_DIR/evidence-report.txt"

lines=()
lines+=("=== CVNP1601-W07 Evidence Report ===")
lines+=("Generated : $(date '+%Y-%m-%d %H:%M:%S')")
lines+=("Host      : $(hostname 2>/dev/null || uname -n)")
lines+=("Week      : 07")
lines+=("Folder    : $WEEK_DIR")
lines+=("")

# ── Effective sshd configuration ──────────────────────────────────────────────
# Proves Task 2: password auth disabled, pubkey auth enabled — the running
# config, not just what's written in the file.
lines+=("[EFFECTIVE SSHD CONFIG — sudo sshd -T]")
if output=$(sudo sshd -T 2>&1 | grep -E '^(passwordauthentication|pubkeyauthentication) '); then
    while IFS= read -r l; do lines+=("  $l"); done <<< "$output"
else
    lines+=("  sudo sshd -T failed or not available on this host (needs root): rerun as a user with sudo access")
fi
lines+=("")

# ── ufw status ─────────────────────────────────────────────────────────────────
# Proves Task 3: default-deny baseline with SSH allowed and firewall active.
lines+=("[UFW STATUS — sudo ufw status verbose]")
if output=$(sudo ufw status verbose 2>&1); then
    while IFS= read -r l; do lines+=("  $l"); done <<< "$output"
else
    lines+=("  ufw status query failed or ufw not installed: $output")
fi
lines+=("")

# ── Sensitive file permissions ────────────────────────────────────────────────
# Proves Task 4: least-privilege permissions on .ssh, authorized_keys, and the
# hardening script. Never reads file contents — permission bits only.
lines+=("[SENSITIVE FILE PERMISSIONS — ls -la]")
for p in "$HOME/.ssh" "$HOME/.ssh/authorized_keys" "$HOME/scripts/harden.sh"; do
    if [ -e "$p" ]; then
        lines+=("  $(ls -ld "$p" 2>&1)")
    else
        lines+=("  $p not present on this host")
    fi
done
lines+=("")

# ── Required files ────────────────────────────────────────────────────────────
# Every deliverable the Week 07 assignment requires. Keep this array in sync
# with the assignment's Submission Checklist.
lines+=("[REQUIRED FILES]")
REQUIRED_FILES=(
    "README.md"
    "week1-cheatsheet.txt"
    "tech-lead-note.md"
    "troubleshooting-narrative.md"
    "week7-diagnosis.md"
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
# careless leaks (pasted tokens, private keys, literal passwords). Private-key
# material is especially critical to catch this week.
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
    lines+=("  No obvious secret/token patterns detected. Still manually review every file before committing — never commit private key contents.")
fi
lines+=("")

lines+=("Commit this file (evidence-report.txt) to your GitHub repo under week07-server-hardening/.")

printf '%s\n' "${lines[@]}" >"$OUT_FILE"
printf '%s\n' "${lines[@]}"
