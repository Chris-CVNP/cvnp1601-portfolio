#!/bin/bash
# Script:  health_report.sh
# Author:  C A
# Course:  CVNP1601 Linux Administration, Week 12
# Ticket:  CVNP1601-W12-012
# Purpose: Write a health report that another technician can review
#          without logging in. The report starts with the hostname and
#          timestamp, then labeled sections for disk, inodes, memory,
#          load, vmstat, and listening services.
# Usage:   bash ~/scripts/health_report.sh
#          Scheduled from cron for a daily 6:00 AM run.

# WHY: Report paths are set once in variables so they are easy to find and change.
REPORT_DIR="$HOME/reports"
HOST="$(hostname)"
STAMP="$(date +%Y%m%d_%H%M%S)"
REPORT_FILE="$REPORT_DIR/health_${HOST}_${STAMP}.log"

# WHY: mkdir -p creates the reports directory if it is missing so the redirect below cannot fail on a missing path.
mkdir -p "$REPORT_DIR"

# WHY: All output is grouped so one redirect writes the whole report to a timestamped file.
{
    # WHY: Hostname and timestamp come first so a reviewer knows which server and when before reading any metric.
    echo "Host: $HOST"
    echo "Date: $(date)"
    echo

    # WHY: df -h shows disk space per filesystem. Use% above 85% needs attention.
    echo "=== Disk Usage: df -h ==="
    df -h
    echo

    # WHY: df -i shows inode usage, which can run out even when disk space looks fine.
    echo "=== Inode Usage: df -i ==="
    df -i
    echo

    # WHY: The available column shows memory the system can hand to applications, including reclaimable cache.
    echo "=== Memory: free -h ==="
    free -h
    echo

    # WHY: Load averages only mean something next to the CPU core count.
    echo "=== Load: uptime and nproc ==="
    uptime
    echo "CPU cores: $(nproc)"
    echo

    # WHY: vmstat 1 5 takes five live samples. The first line is a since-boot average and is skipped when reading.
    echo "=== CPU and I/O Samples: vmstat 1 5 ==="
    vmstat 1 5
    echo

    # WHY: ss -tlnp lists the TCP ports the server is listening on.
    echo "=== Listening Services: ss -tlnp ==="
    ss -tlnp
} > "$REPORT_FILE" 2>&1

echo "Report written to $REPORT_FILE"

