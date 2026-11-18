# CVNP1601 Week 13: Incident Triage
Ticket: CVNP1601-W13-013, Troubleshooting Under Pressure

---

## Objectives
- Triage simultaneous failures by impact: service-affecting first, then degraded health, then maintenance
- Capture journal evidence before restarting a failed service and validate the config with nginx -t
- Diagnose disk pressure with df and du, and clear a file safely with truncate after checking lsof
- Diagnose and repair a web root ownership failure with a scoped chown -R, never chmod 777
- Write a post-incident report with hostname, timestamp, root cause, fix, verification, and time to resolution
- Diagnose a break/fix scenario where the service manager reports failed but the site still answers

---

## Tools Used
- find
- mkdir
- nano
- systemctl
- journalctl
- nginx -t
- df
- dd
- du
- sort
- head
- lsof
- truncate
- chown
- curl
- ls
- cat
- cp
- diff
- tail
- scp

---

## Configuration

### Ticket Information
- Ticket ID: CVNP1601-W13-013
- Submitted by: Operations escalation lead
- Affected system: Ubuntu VM, nginx, /var storage, /var/www/html, cron evidence
- Reported issue: Web service outage with possible storage and permission side effects
- Business impact: Critical
- Security consideration: Guessing during an incident can destroy evidence, widen permissions, or hide the real root cause
- Required outcome: Each symptom diagnosed, fixed one at a time, verified, and documented in a hostname and timestamped incident report

### Scenario Summary
The lab VM, hostname 1601, running Ubuntu Server 24.04 LTS at 10.10.50.103, was given three simultaneous symptoms: a failed nginx service caused by a misspelled config directive, disk pressure from a 500 MB test file in /var/log, and web content under /var/www/html owned by root:root. Each symptom was worked in triage order, one change at a time, with evidence captured before and after each change. A fourth, separate break/fix scenario was diagnosed on paper in week13-diagnosis.md.

---

## Setup

### Step 1: Locate the portfolio repo
```
find ~ -maxdepth 3 -type d -name "*1601*"
```
Expected output includes: /home/REDACTED/cvnp1601-portfolio

Status: Complete

### Step 2: Create the week folder
```
mkdir -p ~/cvnp1601-portfolio/week13-incident-triage/screenshots
```
Expected output includes: no output

Status: Complete

---

## Task 1: Diagnose and Repair a Failed Service
Screenshot: screenshots/01-task1-nginx-failure.png

### Step 3: Introduce the config error
```
sudo nano /etc/nginx/sites-enabled/default
```
Expected output includes: server_name changed to server_nmae on line 46 and saved

Status: Complete

### Step 4: Restart nginx
```
sudo systemctl restart nginx
```
Expected output includes: Job for nginx.service failed because the control process exited with error code.

Status: Failed as expected

### Step 5: Check service status
```
systemctl status nginx
```
Expected output includes: Active: failed (Result: exit-code) since Wed 2026-11-18 16:23:36 UTC, and unknown directive "server_nmae"

Status: Complete

### Step 6: Create the reports directory
```
mkdir -p ~/reports
```
Expected output includes: no output

Status: Complete

### Step 7: Capture the journal before the next restart
```
journalctl -u nginx -n 100 --no-pager > ~/reports/diagnosis_$(date +%Y%m%d_%H%M%S).txt
```
Expected output includes: no output. File created: ~/reports/diagnosis_20261118_162435.txt

Status: Complete

### Step 8: Validate the config
```
sudo nginx -t
```
Expected output includes: [emerg] unknown directive "server_nmae" in /etc/nginx/sites-enabled/default:46 and configuration file /etc/nginx/nginx.conf test failed

Status: Complete. Root cause confirmed: the server_nmae directive at line 46.

### Step 9: Restart nginx
```
sudo systemctl restart nginx
```
Expected output includes: Job for nginx.service failed because the control process exited with error code.

Status: Failed. See Issue 2.

### Step 10: Check the active state
```
systemctl is-active nginx
```
Expected output includes: failed

Status: Failed. See Issue 2.

---

## Task 2: Diagnose Disk Pressure Safely
Screenshot: screenshots/02-task2-disk-pressure.png

### Step 11: Free-space check before the fill
```
df -h /var
```
Expected output includes: /dev/mapper/ubuntu--vg-ubuntu--lv 9.8G 3.3G 6.0G 36% /

Status: Complete. 6.0G available, above the 600 MB minimum.

### Step 12: Create the test fill file
```
sudo dd if=/dev/zero of=/var/log/testfill.img bs=1M count=500
```
Expected output includes: 500+0 records in, 500+0 records out, 524288000 bytes copied

Status: Complete

### Step 13: Check disk usage after the fill
```
df -h /var
```
Expected output includes: 9.8G 3.8G 5.5G 42% /

Status: Complete

### Step 14: Find the largest items in /var/log
```
sudo du -sh /var/log/* 2>/dev/null | sort -rh | head -5
```
Expected output includes: 501M /var/log/testfill.img

Status: Complete

### Step 15: Check for open file handles
```
sudo lsof /var/log/testfill.img
```
Expected output includes: no output

Status: Complete. No process had the file open.

### Step 16: Clear the file safely
```
sudo truncate -s 0 /var/log/testfill.img
```
Expected output includes: no output

Status: Complete

### Step 17: Check disk usage after cleanup
```
df -h /var
```
Expected output includes: 9.8G 3.3G 6.0G 36% /

Status: Complete

### Note: truncate versus rm
Truncating an active log may be better than using rm on your Linux box because of how the OS manages open file descriptors. A running process will have an open file descriptor pointing at the inode where the data lives, not the filename, if the process has opened a log file. When you run rm, you are simply removing the directory entry for the file. Since the running process continues to write to the same inode, and does not close the file until either the process closes the file, or the process crashes/restarts, then you will not see disk space get recovered as indicated by running df. If you use truncate -s 0, you empty the contents of the file in-place. Therefore, the service's file descriptor remains valid; the service continues logging normally, and space is immediately recovered without requiring a restart. This is why we always run lsof prior to performing any type of cleanup. In our case, lsof returned no output when queried with regard to testfill.img, therefore no process had testfill.img open. After executing truncate, df again reflected that /var dropped from 42% to 36%.

---

## Task 3: Diagnose and Repair a Permission Failure
Screenshot: screenshots/03-task3-ownership.png

### Step 18: Break the web root ownership
```
sudo chown -R root:root /var/www/html
```
Expected output includes: no output

Status: Complete

### Step 19: Check the HTTP response
```
curl -I http://localhost
```
Expected output includes: curl: (7) Failed to connect to localhost port 80 after 0 ms: Couldn't connect to server

Status: No HTTP response. See Issue 3.

### Step 20: Check ownership before the fix
```
ls -la /var/www/html
```
Expected output includes: root root on . and on index.nginx-debian.html

Status: Complete

### Step 21: Restore the correct ownership
```
sudo chown -R www-data:www-data /var/www/html
```
Expected output includes: no output

Status: Complete

### Step 22: Check ownership after the fix
```
ls -la /var/www/html
```
Expected output includes: www-data www-data on . and on index.nginx-debian.html

Status: Complete

### Step 23: Check the HTTP response after the fix
```
curl -I http://localhost
```
Expected output includes: curl: (7) Failed to connect to localhost port 80 after 0 ms: Couldn't connect to server

Status: No HTTP response. See Issue 3.

---

## Task 4: Write the Post-Incident Report
Screenshot: screenshots/04-task4-report-listing.png

### Step 24: Save the report
```
cat > ~/reports/post_incident_$(date +%Y%m%d_%H%M%S).txt << 'EOF'
```
Report contents entered through the heredoc, ending with EOF. The full report is in post-incident-report.md.

Expected output includes: no output

Status: Complete

### Step 25: List the reports directory
```
ls -la ~/reports
```
Expected output includes: post_incident_20261118_164815.txt, 2666 bytes

Status: Complete

### Step 26: Copy the report into the portfolio folder
```
cp ~/reports/post_incident_*.txt ~/cvnp1601-portfolio/week13-incident-triage/post-incident-report.md
```
Expected output includes: no output

Status: Complete

---

## Task 5: Cheat Sheet Synthesis
Screenshot: screenshots/05-task5-cheatsheet.png

### Step 27: Confirm the master matches the Week 12 copy
```
diff ~/week1-cheatsheet.txt ~/cvnp1601-portfolio/week12-health-report/week1-cheatsheet.txt
```
Expected output includes: no output, the files are identical

Status: Complete

### Step 28: Review the earlier entry format
```
tail -n 80 ~/week1-cheatsheet.txt
```
Expected output includes: the Week 10, Week 11, and Week 12 sections

Status: Complete

### Step 29: Append the Week 13 entries
```
cat >> ~/week1-cheatsheet.txt << 'EOF'
```
Entries entered through the heredoc, ending with EOF.

Expected output includes: no output

Status: Complete

### Step 30: Copy the cheat sheet into the week folder
```
cp ~/week1-cheatsheet.txt ~/cvnp1601-portfolio/week13-incident-triage/week1-cheatsheet.txt
```
Expected output includes: no output

Status: Complete

### Step 31: Confirm the copy
```
diff ~/week1-cheatsheet.txt ~/cvnp1601-portfolio/week13-incident-triage/week1-cheatsheet.txt
```
Expected output includes: no output, the files are identical

Status: Complete

### Step 32: Display the Week 13 section
```
tail -n 16 ~/cvnp1601-portfolio/week13-incident-triage/week1-cheatsheet.txt
```
Expected output includes: CVNP1601 Week 13 Command Cheat Sheet, followed by the truncate, lsof, triage priority, one-change-at-a-time, exit status code, and post-incident report section entries

Status: Complete

### How This Workflow Prepares Me for Weeks 14 to 16
The incident process we followed for Week 13 will directly continue through our Week 14 to 16 work on Docker and Ansible. The habits were identical; the only difference was the tool. When diagnosing a failed container with Docker, it will be done the same way as we did with NGINX this week: Read the container's logs, with docker logs, before you restart or replace anything so that there is a record of the error that caused the failure instead of a clean slate. When running an Ansible playbook, each task completes independently and creates its own report so again the single-step-at-a-time approach combined with pre-and-post verification determine if your deployment can be relied upon. Even when using Ansible to make many changes at one time, I still need documentation of which tasks made which changes and some form of verification immediately thereafter to ensure the actual end-state matches the intended end-state.

---

## Task 6: Break/Fix Diagnostic

### Step 33: Save the diagnosis
```
cat > ~/cvnp1601-portfolio/week13-incident-triage/week13-diagnosis.md << 'EOF'
```
Diagnosis entered through the heredoc, ending with EOF. Paper exercise only, no scenario commands were run on the VM.

Expected output includes: no output

Status: Complete

---

## Written Artifacts

### Step 34: Save the technical lead note
```
cat > ~/cvnp1601-portfolio/week13-incident-triage/tech-lead-note.md << 'EOF'
```
Expected output includes: no output

Status: Complete

### Step 35: Save the troubleshooting narrative
```
cat > ~/cvnp1601-portfolio/week13-incident-triage/troubleshooting-narrative.md << 'EOF'
```
Expected output includes: no output

Status: Complete

### Step 36: Copy the screenshots to the VM, run from PowerShell on Windows
```
scp C:\Users\REDACTED\Desktop\01-task1-nginx-failure.png C:\Users\REDACTED\Desktop\02-task2-disk-pressure.png C:\Users\REDACTED\Desktop\03-task3-ownership.png C:\Users\REDACTED\Desktop\04-task4-report-listing.png C:\Users\REDACTED\Desktop\05-task5-cheatsheet.png REDACTED@10.10.50.103:~/cvnp1601-portfolio/week13-incident-triage/screenshots/
```
Expected output includes: each of the five files listed at 100%

Status: Complete

### Step 37: Confirm the screenshots arrived
```
ls -la ~/cvnp1601-portfolio/week13-incident-triage/screenshots
```
Expected output includes: the five .png files

Status: Complete

### Step 38: Save this README
```
cat > ~/cvnp1601-portfolio/week13-incident-triage/README.md << 'EOF'
```
```
cat >> ~/cvnp1601-portfolio/week13-incident-triage/README.md << 'EOF'
```
The first command wrote the opening part of the file, and the second was repeated for each remaining part, each ending with EOF.

Expected output includes: no output

Status: Complete

---

## Troubleshooting Notes

### Issue 1: Task 1 was run twice
Incorrect command: the first run of the Task 1 sequence, which followed a step list that marked five screenshot points for Task 1 instead of the one screenshot the assignment's Evidence required line calls for.

Root Cause: the step list was built from the guide's per-item screenshot lines instead of the assignment's single Evidence required line for the task.

Resolution: the lab was reset and Task 1 was started over. sudo nano /etc/nginx/sites-enabled/default changed server_nmae back to server_name on line 46, then sudo systemctl restart nginx and systemctl is-active nginx brought the service back before the full Task 1 sequence was run again.

Result: the second run is the one documented in Steps 3 through 10 and in screenshot 01. The status output in that run shows Duration: 1min 22.549s, which confirms nginx was running after the reset. The first run's journal capture, ~/reports/diagnosis_20261118_161545.txt, is still in ~/reports.

### Issue 2: nginx was not restored at the end of Task 1
Incorrect command:
```
sudo systemctl restart nginx
```
Root Cause: the assignment's Task 1 command list has no step to correct the directive between sudo nginx -t and the final restart, and the list was followed as written. server_nmae was still in place at line 46 of /etc/nginx/sites-enabled/default.

Resolution: none applied. The directive was left uncorrected.

Result: the restart failed again, systemctl is-active nginx returned failed, and nginx stayed down for the rest of the lab.

### Issue 3: Task 3 curl returned a connection failure instead of an HTTP response
Incorrect command:
```
curl -I http://localhost
```
Root Cause: nginx was not running because of Issue 2, so nothing was listening on port 80.

Resolution: none for the HTTP check. Ownership before and after the fix was verified with ls -la /var/www/html.

Result: the ownership change was verified. The HTTP response before and after the fix could not be captured.

---

## Portfolio Card

### What I Can Do Now
I can triage a Linux server with simultaneous service, disk, and permission failures, work one issue at a time, preserve journal evidence before a restart, and write an evidence-backed post-incident report.

---

## AI Use Statement
I used Claude to create the cheat sheet and to verify that my rewritten material was technically error-free. I ran all commands directly on my local Virtual Machine and reviewed the output manually. The data and information contained within the reports and notes in this folder were obtained by viewing actual output. Without assistance from the AI, I can provide explanations for why the journal will be captured prior to restarting, why truncating with -s 0 is safer than removing an open log file with rm, and how the orphaned nginx worker in the break/fix example prevented nginx from binding to port 80 while returning a successful response, 200 OK.

---

## Files In This Folder
- README.md: this file
- post-incident-report.md: copy of ~/reports/post_incident_20261118_164815.txt
- week1-cheatsheet.txt: cumulative cheat sheet with the Week 13 entries
- week13-diagnosis.md: Task 6 break/fix diagnosis
- tech-lead-note.md: technical lead note
- troubleshooting-narrative.md: troubleshooting narrative
- collect-evidence.sh: Week 13 evidence script from Brightspace
- evidence-report.txt: output of collect-evidence.sh
- screenshots/01-task1-nginx-failure.png: Task 1 failed service, journal capture, config validation, restart, and active state
- screenshots/02-task2-disk-pressure.png: Task 2 before and after disk usage, largest-file diagnosis, lsof check, and truncate cleanup
- screenshots/03-task3-ownership.png: Task 3 HTTP checks and ownership before and after the fix
- screenshots/04-task4-report-listing.png: Task 4 report file listing in ~/reports
- screenshots/05-task5-cheatsheet.png: Task 5 Week 13 cheat sheet entries
