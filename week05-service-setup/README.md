# Week 5: Managing Software and Services

**Ticket:** CVNP1601-W5-005, Install, enable, verify, and script nginx on a new Ubuntu web server

---

## Objectives

- Install, remove, and verify packages with apt and dpkg
- Manage the nginx service lifecycle with systemctl and prove both active and enabled states
- Write server-setup.sh with a shebang, header block, WHY comments, progress output, and a verification block that exits 1 on failure
- Test the script from a clean state and verify the result independently
- Append Week 5 entries to the running CLI cheat sheet
- Diagnose a masked service break/fix scenario

---

## Tools Used

- apt update
- apt install -y
- apt purge
- apt autoremove
- dpkg -l
- systemctl start, stop, status, enable, is-enabled, is-active, enable --now
- systemctl is-active --quiet
- chmod +x
- bash
- nano
- sed
- grep, tail, cp, diff, ls

---

## Configuration

### Ticket Information

- Ticket ID: CVNP1601-W5-005
- Submitted by: Web hosting operations lead
- Affected system: New Ubuntu web server and nginx service
- Reported request: Install nginx, enable it for boot, verify it is running, and script the setup
- Business impact: High
- Security consideration: A web service must be installed intentionally, verified, and documented
- Required outcome: nginx installed, active, enabled, scripted, tested from clean state, and independently verified
- Lab system: VM 1601, Ubuntu Server 24.04 LTS, 10.10.50.103, reached over SSH

### Scenario Summary

A new Ubuntu server has been provisioned and the manager needs nginx running before a client demo. The real deliverable is repeatability: the next server should be configured by running a script, so the setup has to be scripted, commented, tested from a clean state, and verified rather than assumed.

---

## Task 1: Package Management Practice

```
sudo apt update
```
Expected output includes: "All packages are up to date."
Status: Complete

```
sudo apt install -y nginx
```
Expected output includes: "nginx is already the newest version (1.24.0-2ubuntu7.18)." nginx was already present on the VM. See Troubleshooting Notes, Issue 1.
Status: Complete

```
dpkg -l nginx
```
Expected output includes: "ii  nginx  1.24.0-2ubuntu7.18"
Screenshot: screenshots/01-dpkg-installed.png
Status: Complete

```
dpkg -l nginx
```
Expected output includes: "ii" still present, because the purge step was skipped. See Troubleshooting Notes, Issue 3.
Status: Deviation, corrected

```
sudo apt purge nginx && sudo apt autoremove -y
```
Expected output includes: "Removing nginx (1.24.0-2ubuntu7.18)" and "Removing nginx-common (1.24.0-2ubuntu7.18)"
Status: Complete

```
dpkg -l nginx
```
Expected output includes: "un  nginx  <none>"
Screenshot: screenshots/02-dpkg-removed.png
Status: Complete

**Remove versus purge:** remove only removes the primary program itself. it does not remove the configuration files that are a part of the program, which is what purge does.

---

## Task 2: Service Lifecycle with systemctl

```
sudo apt install -y nginx
```
Expected output includes: "Setting up nginx (1.24.0-2ubuntu7.18)"
Status: Complete

```
sudo systemctl start nginx
```
Expected output includes: no output on success
Status: Complete

```
sudo systemctl status nginx
```
Expected output includes: "Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)" and "Active: active (running)"
Screenshot: screenshots/03-systemctl-status.png
Status: Complete

```
systemctl is-enabled nginx
```
Expected output includes: "enabled" (already enabled at install, see Troubleshooting Notes, Issue 2)
Status: Complete

```
sudo systemctl enable nginx
```
Expected output includes: "Executing: /usr/lib/systemd/systemd-sysv-install enable nginx"
Status: Complete

```
systemctl is-enabled nginx
```
Expected output includes: "enabled"
Screenshot: screenshots/04-is-enabled-before-after.png
Status: Complete

```
sudo systemctl stop nginx
```
Expected output includes: no output on success
Status: Complete

```
systemctl is-active nginx
```
Expected output includes: "inactive"
Status: Complete

```
sudo systemctl enable --now nginx
```
Expected output includes: "Executing: /usr/lib/systemd/systemd-sysv-install enable nginx"
Status: Complete

```
systemctl is-active nginx && systemctl is-enabled nginx
```
Expected output includes: "active" and "enabled"
Status: Complete

**Start versus enable:** Start will start a service at that particular point in time. But on reboot, it will not run until you command it to. Whereas enable lets it start on its own at reboot and doesn't require human interaction.

---

## Task 3: Write server-setup.sh

```
cat > ~/server-setup.sh << 'EOF'
```
Expected output includes: no output. The script was written with a heredoc. Full contents are in server-setup.sh in this folder.
Status: Complete

```
chmod +x ~/server-setup.sh
```
Expected output includes: no output on success
Status: Complete

```
ls -l ~/server-setup.sh
```
Expected output includes: "-rwxrwxr-x"
Status: Complete

```
nano ~/server-setup.sh
```
Expected output includes: the complete script with shebang on line 1, header block, WHY comments, echo progress statements, and the verification block
Screenshot: screenshots/05-server-setup-script.png
Status: Complete

```
cp ~/server-setup.sh ~/cvnp1601-portfolio/week05-service-setup/server-setup.sh
```
Expected output includes: no output on success
Status: Complete

```
sed -i 's/^# Author:  Chris Alsaker$/# Author:  C A/' ~/server-setup.sh
```
```
sed -i 's/^# Author:  Chris Alsaker$/# Author:  C A/' ~/cvnp1601-portfolio/week05-service-setup/server-setup.sh
```
Expected output includes: no output. The Author line was changed to initials in both copies to match the redacted screenshot.
Status: Complete

---

## Task 4: Test on a Clean State

```
sudo apt purge nginx && sudo apt autoremove -y
```
Expected output includes: "Removing nginx (1.24.0-2ubuntu7.18)" and "Removing nginx-common (1.24.0-2ubuntu7.18)"
Status: Complete

```
systemctl status nginx
```
Expected output includes: "Unit nginx.service could not be found."
Screenshot: screenshots/06-clean-state.png
Status: Complete

```
sudo bash ~/server-setup.sh
```
Expected output includes: "[1/4]" through "[4/4]" progress lines, "The following NEW packages will be installed: nginx nginx-common", and "SUCCESS: nginx is active and running"
Screenshot: screenshots/07-script-run-success.png
Status: Complete

```
systemctl is-active nginx
```
Expected output includes: "active"
Status: Complete

```
systemctl is-enabled nginx
```
Expected output includes: "enabled"
Screenshot: screenshots/08-post-run-verification.png
Status: Complete

---

## Task 5: CLI Cheat Sheet Update

```
diff ~/week1-cheatsheet.txt ~/cvnp1601-portfolio/week02-textops/week1-cheatsheet.txt && echo IDENTICAL
```
Expected output includes: "IDENTICAL" (master confirmed against the last committed snapshot before appending)
Status: Complete

```
cat >> ~/week1-cheatsheet.txt << 'EOF'
```
Expected output includes: no output. Nine Week 5 entries appended with >>, each with a Risk/note line, including a security note on enabling network daemons.
Status: Complete

```
grep -n "Command Cheat Sheet" ~/week1-cheatsheet.txt
```
Expected output includes: "1:CVNP1601 Week 1", "95:CVNP1601 Week 2", and "132:CVNP1601 Week 5"
Status: Complete

```
tail -n 50 ~/week1-cheatsheet.txt
```
Expected output includes: the Week 2 awk entry followed by the Week 5 section
Screenshot: screenshots/09-cheatsheet-week5.png
Status: Complete

```
cp ~/week1-cheatsheet.txt ~/cvnp1601-portfolio/week05-service-setup/week1-cheatsheet.txt
```
Expected output includes: no output on success
Status: Complete

```
diff ~/week1-cheatsheet.txt ~/cvnp1601-portfolio/week05-service-setup/week1-cheatsheet.txt && echo IDENTICAL
```
Expected output includes: "IDENTICAL"
Status: Complete

---

## Task 6: Break/Fix Diagnostic

Paper exercise. The web02 transcript is fictional and nothing was run on the lab VM. The answer is in week5-diagnosis.md, covering state, root cause (masked unit), remediation (systemctl unmask nginx before retrying enable --now), and verification from two independent angles.
Status: Complete

---

## Troubleshooting Notes

### Issue 1

- Incorrect command: `sudo apt install -y nginx` at the start of Task 1
- Root Cause: nginx was already installed on the VM before this assignment began, so apt reported "nginx is already the newest version" instead of installing it.
- Resolution: Continued with the Task 1 sequence. The purge in Task 1 and again in Task 4 returned the VM to a clean state before the package was installed from scratch.
- Result: The Task 4 script run installed both nginx and nginx-common as new packages, proving the script works from a clean state.

### Issue 2

- Incorrect command: `systemctl is-enabled nginx` before `sudo systemctl enable nginx` in Task 2
- Root Cause: The nginx unit was already enabled right after install. The Loaded line showed "enabled; preset: enabled", so the disabled-before state the assignment expects never appeared.
- Resolution: Captured the before and after is-enabled output as it actually occurred. No disable step was added, since the assignment does not list one.
- Result: Screenshot 04 shows enabled both before and after, and this note documents why.

### Issue 3

- Incorrect command: `dpkg -l nginx` run twice in a row in Task 1, with the purge step skipped between them
- Root Cause: The purge and autoremove line was never run, so the second dpkg -l still showed ii instead of the removed state.
- Resolution: Ran `sudo apt purge nginx && sudo apt autoremove -y`, answered Y at the purge prompt. Autoremove also removed nginx-common and two unrelated orphaned packages, libfwupd2 and libgusb2.
- Result: `dpkg -l nginx` returned un, captured in screenshot 02.

---

## Portfolio Card

### What I Can Do Now

I can turn a manual nginx setup into a tested, repeatable script with a verification block, so a new web server reaches a known working state without guesswork.

---

## AI Use Statement

I utilized Claude to assist me with this task. I executed every command. I reviewed the output of each command before continuing. Claude corrected inaccuracies in the technical content; however, it did not always provide accurate information. Initially, Claude indicated that my Task 1 Purge had failed. My Terminal Log clearly illustrated that no purge had ever occurred. This was my Troubleshooting Narrative. The section of the script I can explain without AI help is the verification block: systemctl is-active --quiet returns only an exit code, the if statement reads that code, and exit 1 reports the failure to whoever ran the script instead of letting it pass silently.

---

## Files In This Folder

- README.md
- server-setup.sh
- week1-cheatsheet.txt
- week5-diagnosis.md
- tech-lead-note.md
- troubleshooting-narrative.md
- evidence-report.txt
- screenshots/01-dpkg-installed.png
- screenshots/02-dpkg-removed.png
- screenshots/03-systemctl-status.png
- screenshots/04-is-enabled-before-after.png
- screenshots/05-server-setup-script.png
- screenshots/06-clean-state.png
- screenshots/07-script-run-success.png
- screenshots/08-post-run-verification.png
- screenshots/09-cheatsheet-week5.png
