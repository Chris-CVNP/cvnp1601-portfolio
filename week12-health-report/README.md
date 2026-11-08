# Week 12: Automated Server Health Report

Ticket: CVNP1601-W12-012

---

## Objectives

- Collect a manual health baseline for disk, inodes, memory, load, CPU samples, and listening services
- Write health_report.sh with a hostname and timestamp header and labeled report sections
- Run the script manually and verify the written report file
- Schedule the script with cron for a daily 6:00 AM run with a PATH line
- Record all six production standards in the cheat sheet
- Diagnose a stalled scheduled report in the break/fix scenario

## Tools Used

- df -h
- df -i
- free -h
- uptime
- nproc
- vmstat 1 5
- ss -tlnp
- mkdir -p
- nano
- chmod 700
- ls -la
- bash
- tail
- grep -E
- crontab -e
- crontab -l
- cp
- diff
- scp

## Configuration

### Ticket Information

- Ticket ID: CVNP1601-W12-012
- Submitted by: Operations manager
- Affected system: Ubuntu VM, health report script, reports directory, and cron
- Reported request: Create a scheduled server health report with disk, memory, CPU, uptime, and listening-service evidence
- Business impact: Medium
- Required outcome: Script runs manually, report includes hostname and timestamp header, cron schedule is verified, and generated report output is captured
- Lab host: VM 102 on Proxmox, hostname 1601, Ubuntu Server 24.04 LTS, 10.10.50.103

### Scenario Summary

An operations manager needs a weekly health report for a small Linux server fleet that another technician can review without logging in. I collected a manual baseline of the core health indicators, wrote health_report.sh to capture the same indicators into a timestamped report that starts with the hostname and date, ran it by hand to confirm the report contents, and scheduled it with cron for a daily 6:00 AM run. I also recorded the six production standards in my cheat sheet and diagnosed a fellow trainee's scheduled report that stopped producing output.

---

## Task 1: Collect Manual Health Baseline

All commands run on VM 102 as my regular user. Screenshot: screenshots/01-health-baseline.png

```bash
df -h
```
Shows disk space used and available on each mounted filesystem.
Expected output includes: Size, Used, Avail, and Use% for each filesystem.
Status: Completed. Root filesystem at 36%, /boot at 13%.

```bash
df -i
```
Shows inode usage on each mounted filesystem.
Expected output includes: Inodes, IUsed, IFree, and IUse% for each filesystem.
Status: Completed. Root filesystem at 22% IUse%.

```bash
free -h
```
Shows memory and swap usage in human-readable units.
Expected output includes: total, used, free, buff/cache, and available columns.
Status: Completed. 2.7Gi free, 3.3Gi available, no swap configured.

```bash
uptime
```
Shows how long the system has been running and the 1, 5, and 15 minute load averages.
Expected output includes: up time, users, and three load average values.
Status: Completed. Up 23 days, load average 0.00, 0.00, 0.00.

```bash
nproc
```
Shows the number of CPU cores available.
Expected output includes: a single number.
Status: Completed. 4 cores.

```bash
vmstat 1 5
```
Takes five CPU, memory, and I/O samples one second apart.
Expected output includes: five data rows with r, b, si, so, bi, bo, us, sy, id, wa, and st columns.
Status: Completed. Rows 2 through 5 show id 100 and wa 0.

```bash
ss -tlnp
```
Lists listening TCP sockets with numeric addresses and ports.
Expected output includes: LISTEN rows with the local address and port for each listening service.
Status: Completed. Ports 22 and 80 on all addresses, port 53 on loopback only. See Issue 2.

### Health Baseline Notes

From df -h Disk Usage:
The root filesystem has 36% usage, 6.0 G available out of 9.8 G and /boot has 13% usage. All tmpfs mounts have 0-1% usage. There is plenty of room left on each filesystem as none are over 70% capacity, therefore, there are no issues with disk usage.

df -i inode usage:
Shows the root filesystem at 22% IUse% and /boot at 1%, while the tmpfs mounts were at 1%. Inodes are very low across each filesystem; therefore, even if disk space is good, there is no risk of running out of inodes right now.

Memory from free -h:
Shows a total of 3.8 Gi RAM, 2.7 Gi in the free column, 3.3 Gi in the available column and 937 Mi was being used for buff/cache. The important number here is available because Linux uses some of its RAM to store buffer/cache information which can be reclaimed when needed by an application. It also shows 0 B for swap; therefore, this VM does not use swap. Memory is healthy.

uptime - shows the time the machine has been running, 23 Days, and the load averages of 0.00, 0.00 & 0.00 for the last 1, 5 & 15 minutes respectively. nproc - reports 4 CPU Cores. A load of 0.00 on four CPUs indicates there is no work waiting for CPU processing time; therefore, load is healthy.

vmstat 1 5:
I ignored the first line of vmstat output since it represents an average of activity since boot rather than a real-time snapshot. From lines 2 through five: r and b remained steady @ 0; si and so remained @ 0; bi and bo remained @ 0 and the CPU columns displayed values consistent with cpu idle, us = 0, sy = 0, id = 100, wa = 0, st = 0, every single time. During the entire sampling period, the CPU had zero I/O wait and did not page anything into/out-of physical memory.

ss -tlnp Listening Services:
Reports port 22 and port 80 as listening on all IPv4 and IPv6 addresses; port 53 is listening on local IPs, loopback only, 127.0.0.53 and 127.0.0.54 which cannot be accessed remotely. Since I ran ss as non-root and those socket listeners were not owned by me, the process column would be blank.

All in all the server baseline appears to be healthy based upon disk space, inodes, memory utilization, load & CPU.

---

## Task 2: Write health_report.sh

Screenshot: screenshots/02-script-permissions.png

```bash
mkdir -p ~/scripts ~/reports
```
Creates the scripts and reports directories if they do not already exist.
Expected output includes: no output on success.
Status: Completed.

```bash
nano ~/scripts/health_report.sh
```
Opens the script file in nano. The script has a shebang, a header block, ten WHY comments, variables for the report paths, quoted variables, mkdir -p for the report directory, a hostname and date header, and labeled sections for disk, inodes, memory, load, vmstat, and listening services, all redirected into a timestamped report file.
Expected output includes: the saved script. A copy is committed in this folder as health_report.sh.
Status: Completed.

```bash
chmod 700 ~/scripts/health_report.sh
```
Gives the owner read, write, and execute permission and removes all access for group and others.
Expected output includes: no output on success.
Status: Completed.

```bash
ls -la ~/scripts/health_report.sh
```
Verifies the permissions on the script.
Expected output includes: -rwx------
Status: Completed. -rwx------, 2115 bytes.

---

## Task 3: Run Manually and Verify Report Contents

Screenshot: screenshots/03-manual-run-report.png

```bash
bash ~/scripts/health_report.sh
```
Runs the script by hand before cron is trusted with it.
Expected output includes: Report written to followed by the report file path.
Status: Completed. Wrote health_1601_20261108_162952.log.

```bash
ls -la ~/reports
```
Lists the reports directory to confirm the report file was created.
Expected output includes: the new health_1601_ report file.
Status: Completed. health_1601_20261108_162952.log, 2525 bytes.

```bash
tail -80 ~/reports/health_*.log
```
Shows the contents of the written report file.
Expected output includes: Host and Date lines first, then the six labeled sections.
Status: Completed. Host: 1601 and the Date line appear before every metric section.

```bash
grep -E "$(hostname)|Disk|Memory|Load|Listening" ~/reports/health_*.log
```
Confirms the hostname line and the labeled sections are in the written file and not only printed to the terminal.
Expected output includes: the Host line and the Disk, Memory, Load, and Listening section headers.
Status: Completed. All five matched.

### Available Versus Free Memory

The available column is better than the free column to check the status of the memory for several reasons. First, memory, or RAM, that isn't being used by programs is used as a cache on most systems that use the Linux operating system, shown in the buff/cache column. This cache is included in the amount of memory that is available to run new programs and applications. The free column simply includes only the total memory that is unused. Therefore, the free column does not account for the memory used as a cache. Because most of the cache is immediately usable and the kernel can instantly reclaim it if needed, it should be counted along with free memory when calculating the maximum amount of memory that can be allocated to run new applications. If you were to just monitor the free column and read from it, especially on a busy server, it may appear at times to have almost no memory available, yet the server may be running fine. Therefore, monitoring just the free column can lead to false alarms. In my report, I am showing the free column at 2.7 Gi and the available column at 3.3 Gi, with 938 Mi used for buff/cache. The higher value shown in the available column is therefore the best measure of how much memory remains available.

---

## Task 4: Schedule with cron and Capture Automation Evidence

Screenshot of the generated report: screenshots/04-generated-report.png

```bash
crontab -e
```
Opens my crontab in nano. I added these two lines at the bottom, using my own absolute paths, redacted here, in place of the assignment's /home/student example. See Issue 1.

```
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
0 6 * * * /home/[redacted]/scripts/health_report.sh >> /home/[redacted]/reports/health_cron.log 2>&1
```
Expected output includes: crontab: installing new crontab
Status: Completed.

```bash
crontab -l
```
Prints the installed crontab.
Expected output includes: the PATH line and the single 0 6 * * * entry.
Status: Completed.

```bash
tail -40 ~/reports/health_cron.log
```
Shows the cron output and error log for the scheduled run.
Expected output includes: the Report written to line from each scheduled run and no errors.
Status: Completed.

```bash
tail -80 ~/reports/health_*.log
```
Shows the generated health report.
Expected output includes: Host and Date lines followed by all six labeled sections.
Status: Completed.

---

## Task 5: All-Six Standards Check and Cheat Sheet

Screenshot: screenshots/05-standards-cheatsheet.png

```bash
cat >> ~/week1-cheatsheet.txt <<'END'

CVNP1601 Week 12 Production Standards Summary

Week 5: Script header block and WHY comments. Evidence: head -11 ~/scripts/health_report.sh shows the header block, and grep -c "# WHY" ~/scripts/health_report.sh returns 10.
Week 6: Executable permission verified with ls -la. Evidence: ls -la ~/scripts/health_report.sh shows -rwx------, which is 700, owner only.
Week 8: Timestamped log output for scheduled automation. Evidence: crontab -l shows the 0 6 * * * entry appending to ~/reports/health_cron.log with >> and 2>&1, and every run writes a new health_1601_YYYYMMDD_HHMMSS.log file.
Week 9: Journal capture before restart. Evidence: ~/reports/diagnosis_20261022_163046.txt, saved with journalctl --no-pager redirected to a timestamped file before the service restart. Not applicable to health_report.sh, which restarts no service.
Week 10: Network state capture before changes. Evidence: ~/reports/network_20261028_163528.txt before the change and ~/reports/network_postfix_20261028_172947.txt after the fix. Not applicable to health_report.sh, which makes no network change.
Week 12: Hostname and timestamp in the report output header. Evidence: head -2 ~/reports/health_1601_20261108_162952.log prints Host: 1601 and the Date line before any metric section.
END
```
Appends the Week 12 standards section to the end of the master cheat sheet.
Expected output includes: no output on success.
Status: Completed.

```bash
tail -8 ~/week1-cheatsheet.txt
```
Shows the new standards section.
Expected output includes: the section header and one line for each of the six standards.
Status: Completed.

### How health_report.sh Meets the Standards

health_report.sh complies fully with all applicable standards relating to scripts and automation. In addition to the shebang and the header block that provides the script's name, author, course, ticket number, function, and how to use the script, there are also ten WHY comments throughout each section of the script. The permissions of the script have been set to 700 with chmod, and the permissions have been confirmed with ls -la which resulted in -rwx------, therefore only the owner may read, write, or execute the script. Each time the script runs, a new report will be generated as a file with the host name as part of its title along with the date and time. The cron entry will append to health_cron.log using >> and 2>&1. Therefore, each scheduled run will leave evidence of what happened. The cron entry used absolute paths, and the crontab included a PATH line which allows cron to locate df, free, vmstat, and ss. The report begins with the host name and the date prior to any metrics section; thus meeting the Week 12 requirements. Since health_report.sh does not restart services nor modify network settings, neither of the Week 9 journal capture nor Week 10 network capture standards apply. Both captures were completed in their respective weeks and stored in my reports directory.

---

## Task 6: Break/Fix Diagnostic

Written answer in week12-diagnosis.md, covering State, Root Cause, Remediation, Verification, and the security note. The scenario is a paper exercise and was not reproduced on the VM.

---

## Portfolio Folder

```bash
mkdir -p ~/cvnp1601-portfolio/week12-health-report/screenshots
```
```bash
cp ~/scripts/health_report.sh ~/cvnp1601-portfolio/week12-health-report/
```
```bash
cp ~/week1-cheatsheet.txt ~/cvnp1601-portfolio/week12-health-report/
```
```bash
diff ~/week1-cheatsheet.txt ~/cvnp1601-portfolio/week12-health-report/week1-cheatsheet.txt && echo IDENTICAL
```
Creates the week folder, copies the script and the cheat sheet snapshot into it, and confirms the snapshot matches the master copy.
Expected output includes: IDENTICAL
Status: Completed.

The five screenshots were redacted on Windows, renamed, and copied into screenshots/ with scp from PowerShell.
Status: Completed.

---

## Troubleshooting Notes

### Issue 1

Incorrect command:
```
0 6 * * * /home/student/scripts/health_report.sh >> /home/student/reports/health_cron.log 2>&1
```
Root Cause: The assignment's example cron entry uses /home/student, but my user account on this VM is not student, so neither path exists on my system.
Resolution: I used the absolute paths of my own home directory, confirmed by the ls -la output in Task 2 and the report path printed in Task 3.
Result: crontab -l shows the PATH line and the 0 6 * * * entry pointing to paths that exist.

### Issue 2

Command:
```bash
ss -tlnp
```
Root Cause: The Process column was blank. ss only shows the owning process for sockets that belong to the user running it, and the listening sockets belong to system accounts. The assignment lists ss -tlnp without sudo, so I ran it as assigned.
Resolution: None needed. The ports and listening addresses are still shown, which is what the health check needs.
Result: The baseline and the report both record ports 22 and 80 on all addresses and port 53 on loopback only.

### Issue 3

Command:
```
0 6 * * * /home/[redacted]/scripts/health_report.sh >> /home/[redacted]/reports/health_cron.log 2>&1
```
Root Cause: The VM clock runs in UTC, as the Date line in the report shows, and cron uses the server's time zone.
Resolution: I kept the 0 6 * * * schedule the assignment requires.
Result: The job runs at 6:00 AM UTC, which is midnight Central during standard time.

---

## Portfolio Card

### What I Can Do Now

I wrote a Linux health report script that starts each report with the hostname and timestamp, captures disk, inode, memory, load, vmstat, and listening-service data in labeled sections, and runs every day at 6:00 AM from cron with its output and errors logged for review.

## AI Use Statement

I used Claude to draft health_report.sh and to read my baseline output. Claude also checked my rewritten answers for technical errors and wrote the standards lines I added to my cheat sheet. I ran every command myself on my own VM, checked each output against the assignment, confirmed the script ran and wrote a report with the hostname and date header, and installed the cron entry with my own paths instead of the example paths. I can explain without AI help why the available memory column is a better measure than the free column, why the first line of vmstat 1 5 is skipped, and what the cron expression 0 6 * * * means, which is minute 0, hour 6, every day of the month, every month, and every day of the week.

## Files In This Folder

- README.md
- health_report.sh
- week1-cheatsheet.txt
- week12-diagnosis.md
- tech-lead-note.md
- troubleshooting-narrative.md
- collect-evidence.sh
- evidence-report.txt
- screenshots/01-health-baseline.png
- screenshots/02-script-permissions.png
- screenshots/03-manual-run-report.png
- screenshots/04-generated-report.png
- screenshots/05-standards-cheatsheet.png
