#!/usr/bin/env bash
# CVNP1601 Week 14 — Evidence Collection Script (Linux/bash)
# Run from the week's portfolio folder (or pass that folder as $1).
# Saves output to evidence-report.txt in that same folder.
# Commit evidence-report.txt to your GitHub portfolio repo under week14-container-handoff/.
#
# HOW TO RUN:
#   cd week14-container-handoff/
#   bash collect-evidence.sh
#   # then commit the generated evidence-report.txt and push
#
# GOTCHA: with no $1 argument, WEEK_DIR defaults to the script's own directory.
# Keep this script inside week14-container-handoff/ and run it from there so it
# scans the right folder for your required files.
#
# Kept intentionally close to plain POSIX shell (array use is the one
# bash-only feature) so it behaves the same on any Linux student VM.

set -uo pipefail
# NOTE: -e is deliberately NOT set. Several checks below (Docker/Podman not
# installed on a grading host, a container name that doesn't exist yet) are
# expected to return non-zero without the whole report aborting — each such
# call is guarded with an explicit if/else so failures are reported inline
# instead of killing the script.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# Week folder defaults to this script's own directory, but can be overridden by
# passing a path as the first argument — useful for testing against a scratch folder.
WEEK_DIR="${1:-$SCRIPT_DIR}"
OUT_FILE="$WEEK_DIR/evidence-report.txt"

lines=()
lines+=("=== CVNP1601-W14 Evidence Report ===")
lines+=("Generated : $(date '+%Y-%m-%d %H:%M:%S')")
lines+=("Host      : $(hostname 2>/dev/null || uname -n)")
lines+=("Week      : 14")
lines+=("Folder    : $WEEK_DIR")
lines+=("")

# ── Container runtime state ───────────────────────────────────────────────────
# Proves Tasks 1-2: Docker/Podman is available and shows the deployed container.
lines+=("[RUNTIME STATE — docker --version / docker ps]")
if output=$(docker --version 2>&1); then
    lines+=("  version   : $output")
else
    lines+=("  docker --version failed (Docker may not be installed on this host; Podman labs should note that here): $output")
fi
if output=$(docker ps --filter name=helpdesk-web 2>&1); then
    while IFS= read -r l; do lines+=("  $l"); done <<< "$output"
else
    lines+=("  docker ps failed: $output")
fi
lines+=("")

# ── Volume state ───────────────────────────────────────────────────────────────
# Proves Task 4: the named volume exists independently of the container's lifecycle.
lines+=("[VOLUME STATE — docker volume ls]")
if output=$(docker volume ls 2>&1); then
    while IFS= read -r l; do lines+=("  $l"); done <<< "$output"
else
    lines+=("  docker volume ls failed: $output")
fi
lines+=("")

# ── Host port state ───────────────────────────────────────────────────────────
# Confirms whether the expected host port is actually in use, independent of
# what docker ps reports — useful cross-check for the Task 6 diagnostic.
lines+=("[HOST PORT STATE — ss -tlnp :8080]")
if output=$(ss -tlnp 2>&1 | grep ':8080' ); then
    lines+=("  $output")
else
    lines+=("  No listener currently found on :8080 (container may not be running on this host).")
fi
lines+=("")

# ── Required files ────────────────────────────────────────────────────────────
# Every deliverable the Week 14 assignment requires. Keep this array in sync
# with the assignment's Submission Checklist.
lines+=("[REQUIRED FILES]")
REQUIRED_FILES=(
    "README.md"
    "docker-run.txt"
    "tech-lead-note.md"
    "troubleshooting-narrative.md"
    "week14-diagnosis.md"
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

lines+=("Commit this file (evidence-report.txt) to your GitHub repo under week14-container-handoff/.")
lines+=("Screenshots of container launch/verification evidence are not checked above (binary/non-deterministic")
lines+=("filenames) but are still required per the Submission Checklist.")

printf '%s\n' "${lines[@]}" >"$OUT_FILE"
printf '%s\n' "${lines[@]}"
