# CVNP1601 Week 3: Users, Groups, and sudo

Ticket CVNP1601-W3-003. Provision a developer account with group membership and restricted sudo access.

---

## Objectives

- Create a Linux user account named `devuser`
- Create and validate the `developers` group
- Add `devuser` to the `developers` group
- Inspect the three identity files that define the account
- Configure a least-privilege sudoers rule
- Verify authorized administrative access
- Verify unauthorized administrative access is denied
- Document implementation and evidence
- Perform cleanup after verification

---

## Tools Used

- Bash Shell
- useradd
- usermod
- groupadd
- groupdel
- userdel
- passwd
- id
- getent
- grep
- which
- visudo
- sudo
- systemctl
- apt

---

## Configuration

### Ticket Information

- **Ticket ID:** CVNP1601-W3-003
- **Submitted By:** Engineering Manager
- **Affected Systems:** Linux User Accounts, Group Management, Sudoers Policy
- **Priority:** Medium
- **Request:** Provision a developer account with group membership and restricted sudo access for a specific administrative task.

### Lab Environment

- **Host:** 1601
- **OS:** Ubuntu Server 24.04 LTS
- **Platform:** Dell PowerEdge R320 running Proxmox VE, VMID 102
- **Access:** SSH from Windows PowerShell

### Scenario Summary

The Engineering Manager requested the creation of a new Linux user account named `devuser` with membership in the `developers` group. The account required limited administrative privileges permitting the execution of a single service management command without granting full root access. The objective was to follow the principle of least privilege by allowing only one approved command through sudo. Verification was required to confirm that the authorized command succeeded while unrelated privileged commands were denied. Documentation of account creation, group membership, sudo policy, verification testing, and cleanup activities was also required. Several environment differences from the assignment guide were identified and corrected during provisioning, and all are recorded in the Troubleshooting Notes below. All required administrative actions were documented and verified prior to cleanup.

---

## Account Creation

Command:

```bash
sudo useradd -m -s /bin/bash devuser
sudo passwd devuser
```

Verification command:

```bash
id devuser
```

Expected output includes:

Status:

Successful

---

## Identity Record Verification

Verification command:

```bash
grep devuser /etc/passwd
```

Expected output includes:

The seven colon-separated fields are username, password placeholder, UID, primary GID, GECOS comment (empty on this account), home directory, and login shell.

Status:

Successful

---

## Home Directory Verification

Verification command:

```bash
ls -ld /home/devuser
```

Expected output includes:

A prior `ls -la /home/devuser` returned permission denied. The directory exists and is owned by devuser, which is what the verification required.

Status:

Successful

---

## Group Creation and Membership

Command:

```bash
sudo groupadd developers
sudo usermod -aG developers devuser
```

Verification command:

```bash
id devuser
```

Expected output includes:

Status:

Successful

---

## Group Replacement Demonstration

A second group was created so the effect of omitting the append flag would be visible in the output.

Command:

```bash
sudo groupadd testgroup
sudo usermod -aG testgroup devuser
sudo usermod -G developers devuser
```

Verification command:

```bash
id devuser
```

Expected output includes:

The testgroup membership was removed with no warning and no confirmation prompt. Without the append flag, usermod replaces the entire supplementary group list with only the groups named on the command line. Both memberships were restored with `usermod -aG` before continuing.

Status:

Successful

---

## Identity File Inspection

Verification commands:

```bash
grep devuser /etc/passwd
sudo grep devuser /etc/shadow
getent group developers
```

Expected output includes:

The /etc/shadow entry required sudo because the file is readable only by root. The password hash is redacted in the committed screenshot. The nine shadow fields are username, hash, last change, minimum age, maximum age, warning period, inactive period, expiration, and reserved.

Status:

Successful

---

## Service Availability

Verification command:

```bash
systemctl status nginx
```

The unit was not found, as nginx is not installed by default on Ubuntu Server 24.04.

Resolution:

```bash
sudo apt update
sudo apt install nginx
```

Expected output includes:

Status:

Successful

---

## Command Path Resolution

Verification command:

```bash
which systemctl
```

Expected output includes:

The assignment guide uses `/bin/systemctl` in its example rule. The assignment instructs the use of the path returned by the system, so the path above was used in the rule.

Status:

Successful

---

## Sudo Configuration Applied

Command:

```bash
sudo visudo
```

Rule added:

Verification command:

```bash
sudo visudo -c
```

Expected output includes:

Status:

Successful

---

## Authorized Command Test

Example command, run as devuser:

```bash
sudo -u devuser bash
sudo /usr/bin/systemctl restart nginx
systemctl status nginx
```

The restart returned to the prompt with no password prompt and no error. The status output confirmed the service had restarted.

Status:

Successful

---

## Unauthorized Command Test

Example command, run as devuser:

```bash
sudo /usr/bin/systemctl stop nginx
```

Expected output includes:

The command prompted for a password and authenticated before being refused. The refusal came from the policy engine, not from a failed login, which confirms the rule is scoped to the restart action only.

Status:

Successful, access correctly denied

---

## Privilege Verification

Verification command:

```bash
sudo -l
```

Expected output includes:

One permitted command and nothing broader, matching the request in the ticket.

Status:

Successful

---

## Cleanup

Commands, in order:

```bash
sudo visudo
sudo visudo -c
sudo userdel -r devuser
sudo groupdel developers
sudo groupdel testgroup
```

Verification command:

```bash
id devuser
getent group developers
```

Expected output includes:

The sudoers rule was removed before the account was deleted. Removing the account first would leave an orphaned rule naming a username that could later be reassigned to a different person.

Status:

Successful

---

## Troubleshooting Notes

### Issue 1: Service Unit Not Found

Incorrect assumption:

```bash
systemctl status nginx
```

Root Cause:

nginx is not installed by default on Ubuntu Server 24.04. The assignment guide assumes the service is present.

Resolution:

```bash
sudo apt update
sudo apt install nginx
```

Result:

nginx 1.24.0-2ubuntu7.17 installed and running.

### Issue 2: Command Path Returned No Output

Incorrect result:

```bash
which systemctl
```

Root Cause:

The first invocation returned no output, so the binary path could not be confirmed.

Resolution:

```bash
which systemctl
```

Result:

The second invocation returned /usr/bin/systemctl, which was used in the sudoers rule.

### Issue 3: Guide Path Differs From System Path

Guide example:

Root Cause:

The guide example uses /bin/systemctl, which is not the path this system returned. The assignment directs the use of the path found with which systemctl rather than the example path.

Resolution:

Result:

The rule matched and the authorized restart succeeded.

### Issue 4: Nested sudo Verification Refused

Incorrect command:

```bash
sudo -u devuser sudo -l
```

Root Cause:

The nested call asks sudo to execute /usr/bin/sudo as devuser. No rule permits devuser to run the sudo binary, so the request was denied. This is the policy working as intended rather than a configuration fault.

Resolution:

```bash
sudo -u devuser bash
sudo -l
```

Result:

The privilege list was returned, showing exactly one permitted command.

### Issue 5: Substituted Group Lookup Command

Substitution:

```bash
getent group developers
```

Root Cause:

The assignment specifies `grep developers /etc/group`. Both returned the same record on this system. getent queries the name service switch and would also return group data from a directory service such as LDAP or SSSD, while grep reads only the local file.

Result:

Same output, documented here as a deviation from the assignment text.

---

## Portfolio Card

I created a Linux user account with useradd, added group membership with usermod -aG, and used visudo to grant one specific service restart command without giving full root access, then proved the boundary by testing a denied command.

---

## AI Use Statement

I provided both the project details and the instructional material guide to Claude at the beginning of the assignment. All commands were run by me on my own VM with all evidence gathered by myself. The task descriptions, the provisioning report, the Tech Lead Note, the Troubleshooting Report, and the Break/Fix Diagnosis were all written by me after completing multiple drafts using my own words. Technical mistakes in writing I made were corrected via AI as well, such as; how usermod -G works, the role /etc/passwd has within authentication, and where systemctl is located for the sudoers rule. In addition, when I encountered difficulties while running this lab, including an empty response from which systemctl, I requested assistance from AI to help troubleshoot these issues. Furthermore, AI suggested creating a testgroup group prior to executing the -G option so that output could be seen, as noted in the Group Replacement Demonstration section.

---

## Files In This Folder

- README.md, this file
- provisioning-summary.md, provisioning summary for the ticket
- tech-lead-note.md, technical lead summary
- troubleshooting-narrative.md, six question troubleshooting reflection
- week3-diagnosis.md, break/fix diagnostic
- collect-evidence.sh, Week 3 evidence collection script
- evidence-report.txt, generated evidence report
- screenshots/, lab evidence captures
