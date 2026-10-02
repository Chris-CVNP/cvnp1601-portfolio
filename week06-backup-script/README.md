# Week 06: Production Bash Script and Git

**Ticket:** CVNP1601-W6-006

---

## Objectives

- Build a production-standard bash script that archives /etc
- Log every major step with timestamps to the terminal and a persistent log file using tee -a
- Test tar's exit status directly in an if block and exit 1 on failure
- Track the script in Git on the Linux system with at least two meaningful commits
- Trace a realistic failure path through the error-handling block
- Update the cumulative CLI cheat sheet with Week 6 entries

## Tools Used

- mkdir
- nano
- chmod
- ls
- sudo
- bash
- tail
- cat
- git init
- git status
- git add
- git commit
- git log

---

## Configuration

### Ticket Information

- **Ticket ID:** CVNP1601-W6-006
- **Submitted by:** Infrastructure operations lead
- **Affected system:** Local Ubuntu VM, /etc backup workflow, and script repository
- **Reported request:** Create a production-standard script that archives /etc, logs every major step, handles failure, and is tracked in Git.
- **Business impact:** High
- **Security consideration:** Backups are incident-recovery evidence. A silent failure or undocumented script change can make recovery unreliable during an outage.

### Scenario Summary

As a junior sysadmin on an infrastructure team, I replaced a previous technician's manual /etc backup process, which had no logging, no failure handling, and no version history. The new script, backup_etc.sh, archives /etc to a timestamped file, logs every major step, exits with a failure status when the archive step fails, and is tracked in Git so another technician can review, run, and audit it.

---

## Task 1: Build the Script Skeleton

```bash
mkdir -p ~/scripts
```
Expected output includes: no output; ~/scripts is created if it does not already exist.

```bash
nano ~/scripts/backup_etc.sh
```
Expected output includes: the script with the shebang, header block, the four variables (BACKUP_DIR, TIMESTAMP, ARCHIVE, LOG), and WHY comments. See screenshots/task1-script-editor.png.

```bash
chmod +x ~/scripts/backup_etc.sh
```
Expected output includes: no output; the execute permission is set.

```bash
ls -la ~/scripts/backup_etc.sh
```
Expected output includes: -rwxrwxr-x permissions on backup_etc.sh. See screenshots/task1-permissions.png.

**Status:** Complete

**Shebang and variables:** The shebang on line 1, #!/bin/bash, tells the system which interpreter should execute the file, as opposed to falling back to /bin/sh which may not have all of the features that bash has. Variables such as BACKUP_DIR, TIMESTAMP, ARCHIVE, and LOG are defined at the beginning of the file, this way each directory/file reference in the code will be in one spot, making an update such as changing a backup area, a simple single-line update vs having to look throughout the entire script for references. Additionally, defining variables at the beginning allows other technicians to know immediately which files/directories the script is going to access before they read through the rest of the scripting logic.

---

## Task 2: Add Logging and Error Handling

```bash
nano ~/scripts/backup_etc.sh
```
Expected output includes: the log() function using tee -a, mkdir -p "$BACKUP_DIR", and the if tar ...; then ... else ... fi block with exit 1 added below the variables.

```bash
sudo bash ~/scripts/backup_etc.sh
```
Expected output includes: timestamped "Starting /etc backup" and "Backup succeeded: /var/backups/etc/etc_20261001_235838.tar.gz" lines.

```bash
tail -20 /var/log/backup_etc.log
```
Expected output includes: the same two timestamped lines, written to the log file.

```bash
ls -lh /var/backups/etc
```
Expected output includes: etc_20261001_235838.tar.gz at 664K, owned by root.

See screenshots/task2-run-log-archive.png.

**Status:** Complete

**Why tee -a is better than plain echo:** This plain echo command will simply print out the message on the terminal screen. Once the session has ended or if you close the terminal all evidence that your backup executed will disappear. If you use tee -a in conjunction with the log function then the timestamped messages are sent to both the terminal screen and appended to /var/log/backup_etc.log. This way, you have the ability to watch your backup as it runs live and leave behind documentation for someone else to read when the script executes without intervention from cron. The -a option tells Tee to append new entries to the end of the existing file rather than replacing everything. This allows multiple technicians to view a single file containing records of every time the script was run, should an auditor need to verify what was done or if there were issues needing to be fixed.

---

## Task 3: Track the Script in Git

```bash
cd ~/scripts
```
Expected output includes: no output; the prompt changes to ~/scripts.

```bash
git init
```
Expected output includes: Initialized empty Git repository in /home/steelbyte/scripts/.git/

```bash
git status
```
Expected output includes: On branch main, No commits yet, and backup_etc.sh listed under Untracked files.

```bash
git add backup_etc.sh
```
Expected output includes: no output; the file is staged.

```bash
git commit -m "Create backup script with logging"
```
Expected output includes: [main (root-commit) 8047be4] Create backup script with logging, 1 file changed, 55 insertions(+).

```bash
nano ~/scripts/backup_etc.sh
```
Expected output includes: the Archive details verification line and its two comment lines added under the Backup succeeded line. See Troubleshooting Notes, Issue 1.

```bash
git add backup_etc.sh
```
Expected output includes: no output; the change is staged.

```bash
git commit -m "Add verification output for archive path"
```
Expected output includes: [main 203ac24] Add verification output for archive path, 1 file changed, 3 insertions(+).

```bash
git log --oneline
```
Expected output includes: 203ac24 Add verification output for archive path and 8047be4 Create backup script with logging.

See screenshots/task3-git-status-log.png.

**Status:** Complete

---

## Task 4: Failure Review and Code Trace

**Failure path:** missing permission (the script is run without sudo).

```bash
if tar -czf "$ARCHIVE" /etc 2>/dev/null; then
  log "Backup succeeded: $ARCHIVE"
  # Record the archive's size and permissions in the log so the run
  # proves the file exists and is not empty, not just that tar exited 0.
  log "Archive details: $(ls -lh "$ARCHIVE")"
else
  log "ERROR: Backup failed"
  exit 1
fi
```

**Code trace:** If the script runs without being executed as root (sudo), the regular user will be unable to write a new archive to /var/backups/etc because that directory is owned by root. In addition, the regular user will be unable to read root-only files located under /etc. The line that checks for the failure is if tar -czf "$ARCHIVE" /etc 2>/dev/null; then. As tar can't create the archive, it will exit with a non-zero exit status. So the if condition is false, and bash will skip the successful branch completely. Instead, bash goes to the else-branch of the conditional statement, and logs "ERROR: Backup failed" to the screen with a date/time stamp using log "ERROR: Backup failed". It then uses exit 1 to stop execution of the script and send back a failure status to whatever invoked it. First, I would examine the terminal output, which would display "ERROR: Backup failed", and the exit code using echo $?, which would show 1 rather than 0. Next, I would expect a tee permission error when attempting to append to /var/log/backup_etc.log because a regular user does not have the appropriate permissions to append to this log file. So, there should be no entry added to this log file from this attempted run. The last thing is, I would expect that ls -lh /var/backups/etc would show no new archive created during this run. One limitation that this trace highlights is that 2>/dev/null suppresses tar's own error messages. Even though the terminal displays that the backup has failed, it doesn't give you any information about why the backup failed.

**Status:** Complete

---

## Task 5: CLI Cheat Sheet Update

```bash
cat >> ~/week1-cheatsheet.txt <<'EOF'
```
Expected output includes: no output; the Week 6 entries are appended to the end of the file without overwriting earlier weeks.

```bash
cat ~/week1-cheatsheet.txt
```
Expected output includes: the previous weeks' entries followed by the CVNP1601 Week 6 Command Cheat Sheet section, with the audit note under git log. See screenshots/task5-cheatsheet.png.

**Status:** Complete

---

## Task 6: Break/Fix Diagnostic

See week6-diagnosis.md.

**Status:** Complete

---

## Troubleshooting Notes

**Issue 1**

```bash
nano ~/scripts/backup_etc.sh
```

- **Root Cause:** While adding the verification line for the second commit, the paste went into the middle of the existing log "Backup succeeded: $ARCHIVE" line instead of onto a new line below it. That split the line and left mismatched quotation marks in the success branch.
- **Resolution:** I exited nano without saving, which left the file as it was at the first commit. I then reopened it and redid the edit with the cursor on a new empty line under the Backup succeeded line.
- **Result:** The success branch is correct, and git commit reported 1 file changed, 3 insertions(+), matching the two comment lines and one log line.

---

## Portfolio Card

### What I Can Do Now

I can build a production-ready bash backup script that archives /etc with timestamped logging, exits on failure so errors are never silent, and is tracked in Git with an auditable commit history.

---

## AI Use Statement

I used Claude to help me complete this assignment. Claude generated the Week 6 cheat sheet entries. I provided Claude with my assignment and had it review my outputs for accuracy to ensure I didn't leave out any steps or mistype any commands. I personally executed each command and confirmed the output before proceeding. I confirmed the script execution, timestamped log entries, archive listing, and both Git commits. I identified errors as they arose. For example, cheat sheet entries didn't match the format I used in previous weeks. Without AI help, I can explain the if tar block: tar is tested directly in the if condition, so a non-zero exit status sends the script to the else branch, which logs the error and exits with status 1. I can also explain why piping tar into tee hides a failure, since a pipeline returns the exit status of its last command.

---

## Files In This Folder

- README.md
- backup_etc.sh
- week1-cheatsheet.txt
- week6-diagnosis.md
- tech-lead-note.md
- troubleshooting-narrative.md
- collect-evidence.sh
- evidence-report.txt
- screenshots/task1-script-editor.png
- screenshots/task1-permissions.png
- screenshots/task2-run-log-archive.png
- screenshots/task3-git-status-log.png
- screenshots/task5-cheatsheet.png
