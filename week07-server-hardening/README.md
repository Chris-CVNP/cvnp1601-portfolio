# CVNP1601 Week 7: SSH Hardening and Firewall Baseline

**Ticket:** CVNP1601-W7-007

---

## Objectives

- Verify that SSH key login works prior to depending on it as the only login method
- Confirm that password authentication is disabled by checking the effective sshd configuration
- Enable a default deny ufw firewall with the SSH allow rule added first
- Apply least privilege permissions to a script, the .ssh directory, and authorized_keys, and verify each with ls -la
- Audit my home directory for world writable items
- Document the two places where the hardening was already in place before this assignment

---

## Tools Used

- `dir`, `ssh`, `ls -la`
- `cp`, `nano`, `systemctl reload ssh`, `sshd -T`, `grep`
- `ufw`
- `mkdir`, `touch`, `chmod`, `find`
- `cat`, `tail`

---

## Configuration

### Ticket Information

- **Ticket ID:** CVNP1601-W7-007
- **Submitted by:** Security operations lead
- **Affected system:** Ubuntu SSH service, ufw firewall, admin scripts, and ~/.ssh/authorized_keys
- **Business impact:** Critical
- **Required outcome:** Key login verified, password auth disabled and verified with effective config, ufw active with SSH allowed, and file permissions locked down with evidence

### Scenario Summary

As a junior sysadmin, I was tasked with applying a hardening baseline to an Ubuntu server before it is used internally. The lead wanted proof that key login works before password login is disabled, that the firewall allows SSH before it is enabled, and that all sensitive files have safe permissions. Since my VM runs on my homelab server rather than in VMware, the SSH key and the password authentication settings were already in place from the day I built it; those two items are documented as deviations in the Troubleshooting Notes.

---

## Steps Taken

### Step 1. Verify SSH key login

List the public key file on the Windows desktop:

```
dir $env:USERPROFILE\.ssh\*.pub
```

Log in to the VM with the key:

```
ssh [username]@10.10.50.103
```

Show that authorized_keys is present on the server:

```
ls -la ~/.ssh ~/.ssh/authorized_keys
```

**Expected output includes:** id_ed25519.pub in the listing, the Ubuntu banner with no password prompt, and authorized_keys at -rw------- inside a .ssh directory at drwx------.

**Status:** Complete with a deviation. ssh-keygen and ssh-copy-id were not run. See Issue 1. Evidence: screenshots/01-key-login-authorized-keys.png.

### Step 2. Disable password authentication safely

Back up the SSH daemon configuration:

```
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
```

Open the file and confirm the two directives:

```
sudo nano /etc/ssh/sshd_config
```

Reload the daemon:

```
sudo systemctl reload ssh
```

Print the effective configuration:

```
sudo sshd -T | grep -E 'passwordauthentication|pubkeyauthentication'
```

**Expected output includes:** PasswordAuthentication no and PubkeyAuthentication yes uncommented in the file, and sshd -T reporting pubkeyauthentication yes and passwordauthentication no.

**Status:** Complete with a deviation. Both directives were already set. See Issue 2 and Issue 3. Evidence: screenshots/02-sshd-config-directives.png and screenshots/03-backup-reload-sshd-effective.png.

Reload versus restart is better to use when you are using SSH hardening, since reload tells the sshd daemon to read the config file again while still running, allowing your current session to stay active for correcting mistakes; whereas restarting completely stops the daemon, and if there is an error in the config file, the daemon will likely not start again at all and you will be unable to connect via SSH.

### Step 3. Configure ufw with a default deny baseline

Set the incoming default policy:

```
sudo ufw default deny incoming
```

Set the outgoing default policy:

```
sudo ufw default allow outgoing
```

Add the SSH allow rule before enabling:

```
sudo ufw allow ssh
```

Enable the firewall:

```
sudo ufw enable
```

Display the active rule set:

```
sudo ufw status verbose
```

**Expected output includes:** both default policies reported as changed, Rules updated for IPv4 and IPv6, Firewall is active and enabled on system startup, and Status: active with 22/tcp ALLOW IN.

**Status:** Complete. The SSH allow rule was added prior to enabling the firewall and my session stayed connected. Evidence: screenshots/04-ufw-baseline.png.

### Step 4. Lock down permissions

Create the scripts directory and the script file:

```
mkdir -p ~/scripts
```

```
touch ~/scripts/harden.sh
```

Restrict the script and the .ssh directory to the owner:

```
chmod 700 ~/scripts/harden.sh
```

```
chmod 700 ~/.ssh
```

Restrict authorized_keys to owner read and write:

```
chmod 600 ~/.ssh/authorized_keys
```

Verify the permissions:

```
ls -la ~/scripts/harden.sh ~/.ssh ~/.ssh/authorized_keys
```

Audit the home directory for world writable items:

```
find ~ -perm -o+w -ls
```

**Expected output includes:** harden.sh at -rwx------, authorized_keys at -rw-------, the .ssh directory at drwx------, and no output from find.

**Status:** Complete. Evidence: screenshots/05-permissions-audit.png.

In order to audit my home directory for world writable items, i used the command find ~ -perm -o+w -ls. Because there were no results shown by this command, there are no files or folders within my home directory providing write permissions to other users.

### Step 5. Final hardening verification and cheat sheet

Confirm password authentication is off and key authentication is on:

```
sudo sshd -T | grep passwordauthentication
```

```
sudo sshd -T | grep pubkeyauthentication
```

Confirm the firewall state:

```
sudo ufw status verbose
```

Confirm the permissions:

```
ls -la ~/.ssh ~/.ssh/authorized_keys ~/scripts/harden.sh
```

Append the Week 7 entries to the cheat sheet and display them:

```
cat >> ~/week1-cheatsheet.txt
```

```
tail -n 58 ~/week1-cheatsheet.txt
```

**Expected output includes:** passwordauthentication no, pubkeyauthentication yes, Status: active, the same permissions as Step 4, and the Week 7 block at the end of the cheat sheet with the LOCKOUT RISK note under ufw enable.

**Status:** Complete. Evidence: screenshots/06-final-verification.png and screenshots/07-cheatsheet-week7.png.

### Step 6. Break and fix diagnostic

**Status:** Complete. The four sections and the security note are in week7-diagnosis.md.

---

## Troubleshooting Notes

### Issue 1: SSH key pair already existed before this assignment

**Commands not run:**

```
ssh-keygen -t ed25519 -C "cvnp1601-week7"
```

```
ssh-copy-id student@SERVER_IP
```

**Root Cause:** Most of the class runs their VM in VMware, where only that local computer can reach it. My VM is running on my homelab server under Proxmox, on a network with other hosts and VMs. Because of that, I secured it the day I built it at the beginning of the semester. That included generating an ed25519 key pair on my Windows desktop as well as on my laptop and installing both public keys on the VM. Running ssh-keygen again at the default path would have overwritten a working key that I use to administer the VM.

**Resolution:** I kept the existing key pairs and did not generate a new one. The public keys were installed by manually appending the contents of each .pub file to authorized_keys on the VM, because ssh-copy-id is not included in the Windows OpenSSH client. The original steps are documented in my homelab repo as Step 7 and Step 8: https://github.com/Chris-CVNP/homelab/blob/main/ubuntu-lab-build/README.md

**Result:** Key login works. Screenshot 01-key-login-authorized-keys.png shows the public key file on my desktop dated 8/26/2026, a successful key login to the VM with no password prompt, and authorized_keys present on the server with 600 permissions inside a .ssh directory set to 700.

### Issue 2: Password authentication was already disabled before this assignment

**Root Cause:** When I created this VM at the start of the semester, I had disabled password based authentication. Since the VM is on my homelab network, which has several other hosts, I chose not to have password based logins enabled. In Task 2 when opening sshd_config using nano, PasswordAuthentication no and PubkeyAuthentication yes were both already set and not commented out, so neither of those lines had to be changed.

**Resolution:** All of the Task 2 commands were run as-is. A backup was made of sshd_config; nano was used to open this file; both of the directives were confirmed; the sshd daemon was reloaded; and the effective configuration for the sshd daemon was tested using sshd -T. I reran three of the commands to leave enough screen space to take a single screenshot showing the successful completion of the three commands: backup, reload, and sshd -T. The original hardening is documented in my Homelab repository under Step 10: https://github.com/Chris-CVNP/homelab/blob/main/ubuntu-lab-build/README.md

**Result:** sshd -T reports pubkeyauthentication yes and passwordauthentication no. A second session from my desktop logged in with the key after the reload, before I closed the first session.

### Issue 3: Login test run from the wrong machine

**Incorrect command,** entered at the prompt of the VM instead of on my desktop:

```
ssh [username]@10.10.50.103
```

**Root Cause:** After the reload in Task 2, I ran the second login test from within the VM itself. The VM then attempted to log in to itself using a key that is not listed in authorized_keys, and the server returned Permission denied publickey.

**Resolution:** I kept my original session open and ran the same command from a new PowerShell window on my desktop, which is the client that holds the key pair.

**Result:** The login from my desktop succeeded without a password prompt. The full account is in troubleshooting-narrative.md.

---

## Portfolio Card

### What I Can Do Now

I am able to harden a Linux server by verifying SSH key access prior to disabling password based logins, confirming the effective sshd configuration using sshd -T, enabling a default deny ufw firewall with SSH allowed first, and verifying least privilege permissions on scripts and SSH files using ls -la.

---

## AI Use Statement

I used Claude as an AI tool on this assignment. I used it to compare my screenshots against the evidence required for each task, plan a process to complete the assignment without generating a new key pair, create the cheat sheet entries, and check my rewrites for technical errors. I ran every command myself on my own, and the decision to keep my existing key pair and document the deviations in Task 1 and Task 2 was mine. I verified the technical claims against my own terminal output. Without AI assistance, I can explain why ufw allow ssh must run before ufw enable, and why authorized_keys is set to 600 while a script is set to 700.

---

## Files In This Folder

- README.md, this document
- tech-lead-note.md, technical lead note
- troubleshooting-narrative.md, the six troubleshooting questions
- week7-diagnosis.md, break and fix diagnostic
- week1-cheatsheet.txt, cumulative cheat sheet with Week 7 entries
- collect-evidence.sh, Week 7 evidence script from Brightspace
- evidence-report.txt, output of collect-evidence.sh
- screenshots/01-key-login-authorized-keys.png, key file listing, key login, and authorized_keys
- screenshots/02-sshd-config-directives.png, the two directives in sshd_config
- screenshots/03-backup-reload-sshd-effective.png, backup, reload, and effective configuration
- screenshots/04-ufw-baseline.png, ufw defaults, SSH allow rule, enable, and verbose status
- screenshots/05-permissions-audit.png, permissions and world writable audit
- screenshots/06-final-verification.png, final verification bundle
- screenshots/07-cheatsheet-week7.png, updated cheat sheet with the lockout risk note
