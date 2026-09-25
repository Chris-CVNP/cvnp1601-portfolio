#!/bin/bash
# Script:  server-setup.sh
# Purpose: Install nginx, enable it for boot, start it, and verify it is running
#          on a new Ubuntu server so every build ends in the same verified state.
# Author:  C A
# Date:    2026-09-25
# Usage:   sudo bash server-setup.sh

echo "[1/4] Refreshing package lists..."
# The local package index can be stale on a newly provisioned server.
# Refreshing it first makes apt pull the current nginx version from the
# repository instead of an outdated or missing one.
sudo apt update

echo "[2/4] Installing nginx..."
# -y answers yes to apt's confirmation prompt automatically. Without it the
# script would stop and wait for keyboard input, which breaks unattended runs.
sudo apt install -y nginx

echo "[3/4] Enabling and starting nginx..."
# enable alone only sets nginx to start at the next boot, and start alone does
# not survive a reboot. --now does both in one step, so the service is running
# immediately and will come back after every reboot.
sudo systemctl enable --now nginx

echo "[4/4] Verifying nginx service state..."
# A successful install does not prove the service is running, so this checks
# with systemd directly. --quiet suppresses output so only the exit code is used.
# On failure the script prints an error to stderr and exits 1, so a technician
# or calling process sees the failure instead of it passing silently.
if systemctl is-active --quiet nginx; then
  echo "SUCCESS: nginx is active and running"
else
  echo "ERROR: nginx failed to start" >&2
  exit 1
fi
