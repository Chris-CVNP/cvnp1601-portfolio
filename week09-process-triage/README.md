# Week 9: Process Triage and Service Recovery

**Ticket:** CVNP1601-W9-009 | CVNP1601 Linux Administration | C A

## Objectives

- Identify a runaway process by PID, owner, CPU percentage, and command
- Terminate it with SIGTERM first and verify that it ended
- Break nginx with a configuration error and diagnose it from systemctl status and journalctl
- Capture the nginx journal to a timestamped file before any successful restart
- Fix the configuration, validate it with nginx -t, restart nginx, and verify recovery

## Tools Used

- while true; do :; done &
- ps aux --sort=-%cpu
- pgrep -la
- top
- kill
- systemctl status, systemctl restart, systemctl is-active
- nano
- journalctl
- nginx -t
- mkdir, cp, diff

---

## Configuration

### Ticket Information

- Ticket ID: CVNP1601-W9-009
- Submitted by: Help desk escalation queue
- Affected system: Ubuntu VM, process table, nginx service, and systemd journal
- Reported issue: Server is slow and nginx fails to start.
- Business impact: High
- Security consideration: Killing processes without checking ownership can terminate the wrong workload. Restarting failed services before capturing logs destroys incident evidence and weakens auditability.
- Required outcome: Runaway process identified and safely terminated; nginx failure captured, fixed, restarted, and verified active.
- Lab system: VM 1601, Ubuntu Server 24.04 LTS on Proxmox VE

### Scenario Summary

Users reported that the internal web page was unavailable, and monitoring showed the Linux VM running hot. As the junior sysadmin on the ticket, I simulated a runaway process, identified it by PID, owner, CPU percentage, and command, and terminated it with SIGTERM. I then broke nginx with a configuration error, diagnosed the failure from systemctl status and journalctl, captured the journal to a timestamped file before fixing anything, corrected the configuration, validated it, restarted nginx, and verified that the service recovered.

---
## Task 1: Simulate and Identify CPU Pressure

### Step 1: Start a runaway background loop

```bash
while true; do :; done &
```

What it does: Starts an infinite loop in the background to simulate a runaway process.
Expected output includes: [1] 25577
Status: Complete

### Step 2: Rank processes by CPU usage

```bash
ps aux --sort=-%cpu | head -10
```

What it does: Lists every process sorted by CPU usage, highest first, and keeps the top ten lines.
Expected output includes: PID 25577, owned by the lab user account, at 100 %CPU, STAT R, command -bash
Status: Complete, screenshot 01-cpu-identify.png

### Step 3: Find bash processes by name

```bash
pgrep -la bash
```

What it does: Lists the PID and full command line of every process matching bash.
Expected output includes: 25568 -bash and 25577 -bash
Status: Complete

### Step 4: Watch CPU usage live

```bash
top
```

What it does: Shows a live, refreshing view of the process table. Pressed q to exit.
Expected output includes: PID 25577 at 100.0 %CPU in state R, and overall CPU at 25.0 us and 75.0 id
Status: Complete

Why owner and command matter: Checking the owner and command before termination confirms that the process belongs to the expected account and is the workload causing the problem, so the signal does not stop the wrong process or a service another user or system account depends on.

---

## Task 2: Terminate Safely and Verify

### Step 5: Send SIGTERM

```bash
kill 25577
```

What it does: Sends SIGTERM, signal 15, to the loop.
Expected output includes: No output
Status: Complete

### Step 6: Wait

```bash
sleep 3
```

What it does: Waits three seconds so the process has time to exit.
Expected output includes: [1]+ Terminated, followed by the while true loop
Status: Complete

### Step 7: Verify the process ended

```bash
ps aux | grep 25577
```

What it does: Searches the process table for PID 25577.
Expected output includes: Only the grep --color=auto 25577 line itself, so the loop is gone. kill -9 was not needed.
Status: Complete, screenshot 02-sigterm-verify.png

SIGTERM versus SIGKILL: SIGTERM is sent to a program by default from the plain kill command, where the program gets the opportunity to perform its own cleanup before exiting, i.e. flush buffers, close files, release locks. Unlike SIGKILL, which signals that a process has to exit immediately and cannot be caught or ignored, SIGTERM does allow a process to do some cleaning up. For example, in our case, SIGTERM terminated the loop on the first try, as seen through the Terminated job message, and therefore, there was no need for a SIGKILL.

---
## Task 3: Break and Diagnose nginx

### Step 8: Check nginx before the change

```bash
sudo systemctl status nginx
```

What it does: Shows the nginx unit state. nginx was already installed, so no install was needed.
Expected output includes: Loaded, enabled, and Active: active (running) since Thu 2026-10-15
Status: Complete

### Step 9: Introduce the configuration error

```bash
sudo nano /etc/nginx/nginx.conf
```

What it does: Opens the main nginx configuration. Removed the semicolon from the end of worker_connections 768; in the events block, then saved and exited.
Expected output includes: No output
Status: Complete

### Step 10: Restart nginx with the error in place

```bash
sudo systemctl restart nginx
```

What it does: Attempts to restart nginx, which runs the configuration test first.
Expected output includes: The restart failed
Status: Complete

### Step 11: Read the failed status

```bash
systemctl status nginx
```

What it does: Shows the headline state of the failed unit.
Expected output includes: Active: failed (Result: exit-code), unexpected "}" in /etc/nginx/nginx.conf:10, and configuration file /etc/nginx/nginx.conf test failed
Status: Complete, screenshot 03-nginx-failed-journal.png

### Step 12: Read the full journal

```bash
journalctl -u nginx -n 50 --no-pager
```

What it does: Shows the last 50 journal entries for the nginx unit without a pager.
Expected output includes: Failed start attempts at 16:27:00 and 16:28:25 UTC, each with unexpected "}" in /etc/nginx/nginx.conf:10 and Failed with result 'exit-code'
Status: Complete, screenshot 03-nginx-failed-journal.png

---

## Task 4: Capture Evidence, Fix, Restart, Verify

### Step 13: Create the reports folder

```bash
mkdir -p ~/reports
```

What it does: Creates the reports folder if it does not exist.
Expected output includes: No output
Status: Complete

### Step 14: Capture the journal before the fix

```bash
journalctl -u nginx --no-pager -n 100 > ~/reports/diagnosis_$(date +%Y%m%d_%H%M%S).txt
```

What it does: Saves the last 100 nginx journal entries to a timestamped file.
Expected output includes: No output
Status: Complete

### Step 15: Confirm the capture file

```bash
ls -la ~/reports/diagnosis_*.txt
```

What it does: Lists the capture file with its size and time.
Expected output includes: diagnosis_20261022_163046.txt, 8879 bytes, Oct 22 16:30
Status: Complete, screenshot 04-capture-fix-verify.png

### Step 16: Fix the configuration

```bash
sudo nano /etc/nginx/nginx.conf
```

What it does: Opens the configuration again. Restored the semicolon so the line reads worker_connections 768; then saved and exited.
Expected output includes: No output
Status: Complete

### Step 17: Validate the configuration

```bash
sudo nginx -t
```

What it does: Tests the nginx configuration syntax without starting the service.
Expected output includes: syntax is ok and test is successful
Status: Complete, screenshot 04-capture-fix-verify.png

### Step 18: Restart nginx

```bash
sudo systemctl restart nginx
```

What it does: Restarts nginx with the corrected configuration.
Expected output includes: No output
Status: Complete, screenshot 04-capture-fix-verify.png

### Step 19: Verify recovery

```bash
systemctl is-active --quiet nginx && echo "nginx is up" || echo "nginx is still down"
```

What it does: Checks whether nginx is active and prints a readable result.
Expected output includes: nginx is up
Status: Complete, screenshot 04-capture-fix-verify.png

The capture file was written at 16:30:46 UTC, before the successful restart.

---
## Task 5: Incident Worklog and Cheat Sheet

### Step 20: Append the Week 9 cheat sheet entries

```bash
cat >> ~/week1-cheatsheet.txt << 'EOF'
```

What it does: Appends the CVNP1601 Week 9 Command Cheat Sheet section to the master cheat sheet: ps aux columns, --sort=-%cpu, pgrep -la, kill and kill -9, systemctl status, and journalctl -u, -n, --no-pager, --since, and -p err.
Expected output includes: No output
Status: Complete

### Step 21: Show the new section

```bash
tail -n 52 ~/week1-cheatsheet.txt
```

What it does: Prints the 52 lines of the Week 9 section.
Expected output includes: CVNP1601 Week 9 Command Cheat Sheet and all ten entries
Status: Complete, screenshot 05-cheatsheet.png

### Step 22: Create the week folder

```bash
mkdir -p ~/cvnp1601-portfolio/week09-process-triage
```

What it does: Creates the Week 9 folder in the portfolio repo.
Expected output includes: No output
Status: Complete

### Step 23: Copy the cheat sheet snapshot

```bash
cp ~/week1-cheatsheet.txt ~/cvnp1601-portfolio/week09-process-triage/week1-cheatsheet.txt
```

What it does: Copies the master cheat sheet into the week folder.
Expected output includes: No output
Status: Complete

### Step 24: Confirm the copy

```bash
diff ~/week1-cheatsheet.txt ~/cvnp1601-portfolio/week09-process-triage/week1-cheatsheet.txt
```

What it does: Compares the master and the copy.
Expected output includes: No output, so the files are identical
Status: Complete

The worklog was written to incident-worklog.md.

---

## Task 6: Break/Fix Diagnostic

Paper exercise; nothing was run on the VM. Answers are in week9-diagnosis.md.

---

## Evidence Assembly

### Step 25: Copy the capture file into the week folder

```bash
cp ~/reports/diagnosis_20261022_163046.txt ~/cvnp1601-portfolio/week09-process-triage/
```

What it does: Puts the timestamped journal capture in the folder for submission.
Expected output includes: No output
Status: Complete

### Step 26: Create the screenshots folder

```bash
mkdir -p ~/cvnp1601-portfolio/week09-process-triage/screenshots
```

What it does: Creates the folder for the five screenshots.
Expected output includes: No output
Status: Complete

---

## Troubleshooting Notes

### Issue 1

Command: systemctl status nginx
Root Cause: The status output was longer than the terminal, so systemctl opened it in a pager and the prompt did not return.
Resolution: Pressed q to exit the pager.
Result: Returned to the prompt and continued with journalctl -u nginx -n 50 --no-pager.

### Issue 2

Command: sudo systemctl restart nginx, run a second time
Root Cause: A second restart was issued while the semicolon was still missing, so the configuration test failed again at 16:28:25 UTC.
Resolution: No further restart was attempted until the journal was captured in Task 4.
Result: Both failed starts are recorded in the journal and the capture file, and no successful restart happened before the capture.

---

## Portfolio Card

**What I Can Do Now:** I can identify a runaway Linux process by PID, owner, and command, terminate it safely with SIGTERM before considering SIGKILL, diagnose a failed nginx service from systemctl status and journalctl, capture timestamped journal evidence before restarting, and verify that the service recovered.

## AI Use Statement

I used Claude to verify that all Lab Commands were accurate by cross-referencing them with official man pages and confirming they were technically correct. I executed each one of these commands in my own lab environment and confirmed all results including the nginx down status, the journal entry indicating an nginx error at nginx.conf line 10. I also confirmed the timestamp in my diagnosis file, the output from running nginx -t, and that my nginx was operating properly. Without AI help, I can explain journalctl -u nginx --no-pager -n 100, which pulls the last 100 journal entries for the nginx unit without a pager so they can be saved to a timestamped file before any restart.

## Files In This Folder

- README.md
- collect-evidence.sh
- diagnosis_20261022_163046.txt
- evidence-report.txt
- incident-worklog.md
- tech-lead-note.md
- troubleshooting-narrative.md
- week1-cheatsheet.txt
- week9-diagnosis.md
- screenshots/01-cpu-identify.png
- screenshots/02-sigterm-verify.png
- screenshots/03-nginx-failed-journal.png
- screenshots/04-capture-fix-verify.png
- screenshots/05-cheatsheet.png
