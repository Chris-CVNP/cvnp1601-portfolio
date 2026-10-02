#!/bin/bash
#
# Script:   backup_etc.sh
# Purpose:  Archive /etc to a timestamped tar.gz file so system
#           configuration can be restored after an incident.
# Ticket:   CVNP1601-W6-006
# Author:   C A
# Created:  2026-10-01
# Usage:    sudo bash ~/scripts/backup_etc.sh
# Requires: root privileges, because many files under /etc are
#           readable only by root.

# Variables
# Every path lives here so there is exactly one place to change it,
# and a reviewer can see everything this script touches without
# reading the logic below.

# Where finished archives are stored.
BACKUP_DIR="/var/backups/etc"

# Date and time of this run, used in the archive name so each run
# creates a new file instead of overwriting the previous backup.
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Full path of the archive this run will create.
ARCHIVE="${BACKUP_DIR}/etc_${TIMESTAMP}.tar.gz"

# Persistent log file, so there is a record of every run for auditing.
LOG="/var/log/backup_etc.log"


# Logging function
# Writes a timestamped message to the terminal and appends it to the
# log file, so every run leaves a permanent record even when nobody
# is watching the screen.
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG"
}

log "Starting /etc backup"

# Create the backup directory if it does not exist yet, because tar
# will not create it and would fail without it.
mkdir -p "$BACKUP_DIR"

# Archive step
# tar runs directly inside the if so the script tests tar's own exit
# status. On failure the error is logged and exit 1 tells cron or any
# monitoring tool that the backup did not happen.
if tar -czf "$ARCHIVE" /etc 2>/dev/null; then
  log "Backup succeeded: $ARCHIVE"
  # Record the archive's size and permissions in the log so the run
  # proves the file exists and is not empty, not just that tar exited 0.
  log "Archive details: $(ls -lh "$ARCHIVE")"
else
  log "ERROR: Backup failed"
  exit 1
fi
