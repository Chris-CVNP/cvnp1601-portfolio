#!/bin/bash
# Script: disk_report.sh
# Author: C A
# Course: CVNP1601 Week 8
# Ticket: CVNP1601-W8-008
# Purpose: Records filesystem disk usage with df -h and appends a
#          timestamped report to a log file, so every scheduled cron
#          run leaves evidence that it actually ran.
# Usage: bash ~/scripts/disk_report.sh, or scheduled with cron

# Variables
# HOME is an absolute path, and cron sets it from /etc/passwd, so the
# log path resolves the same way in a terminal and under cron.
LOG_DIR="$HOME/logs"
LOG="$LOG_DIR/disk_report.log"

# Capture the run time once, before any other work, so every line of
# this report carries the time the run started.
STAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Logging function
# Appends a timestamped message to the log. Uses >> so each run adds
# to the history instead of erasing the previous run's evidence.
log() {
  echo "$STAMP - $1" >> "$LOG"
}

# Create the log directory if it does not exist yet, so the first cron
# run cannot fail on a missing directory. The error goes to stderr so
# the 2>&1 redirect in the crontab entry captures it.
if ! mkdir -p "$LOG_DIR"; then
  echo "$STAMP - ERROR: could not create $LOG_DIR" >&2
  exit 1
fi

log "Disk Report Start"
log "Filesystem usage (df -h):"

# Disk usage step
# df runs directly inside the if so the script tests df's own exit
# status. On failure the error is logged and exit 1 reports the failure.
if df -h >> "$LOG" 2>&1; then
  log "Disk Report Complete"
else
  log "ERROR: df -h failed"
  exit 1
fi

# Cron verification notes
# The crontab entry uses the absolute script path and ends with
# >> disk_report_cron.log 2>&1 so errors from a failed run are saved.
# To confirm cron attempted a run: grep CRON /var/log/syslog | tail -20
# To confirm the script itself ran: tail -20 ~/logs/disk_report.log
# disk_report_cron.log stays empty unless a run fails before the
# script's own logging starts.
