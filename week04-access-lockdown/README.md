# CVNP1601 Week 4: Access Lockdown
Ticket CVNP1601-W4-004

## Objectives

- Audit existing permissions on sensitive files and a shared directory before making any changes
- Correct ownership and group permissions on a shared directory with chmod and chown
- Apply the sticky bit to stop team members from deleting each other's files
- Apply SGID so new files inherit the directory's group
- Grant and revoke a named user ACL for a contractor without changing group membership
- Diagnose a failed setuid attempt on a shell script and recommend the correct mechanism

## Tools Used

- ls
- umask
- chmod
- chown
- touch
- rm
- sudo
- useradd
- groupadd
- usermod
- getfacl
- setfacl

## Configuration

### Ticket Information

- Ticket ID: CVNP1601-W4-004
- Submitted by: Development team lead
- Affected system: Shared Linux directory /project
- Business impact: High
- Security consideration: Overly broad permissions can expose or destroy team files. Contractor access must be specific and removable.
- Required outcome: Sticky bit, SGID, and ACL controls are configured and verified with before and after evidence.

### Scenario Summary

The development team's shared /project directory has three separate problems. Team members can delete each other's files, new files do not consistently belong to the team group, and a contractor named Carlos needs temporary read access without permanent group membership. Each problem needs its own control rather than one broad permission change. The work was performed on Ubuntu Server 24.04 running as VM 102 in Proxmox, with all commands run over SSH as steelbyte.

## Lab Setup

```
sudo useradd -m alice
sudo useradd -m bob
sudo useradd -m carlos
sudo groupadd developers
sudo usermod -aG developers alice
sudo usermod -aG developers bob
sudo mkdir /project
sudo chown root:developers /project
sudo apt install -y acl
id alice
ls -la /
```

Creates the three lab accounts with home directories, creates the shared team group, adds alice and bob to it as a supplementary group, creates the shared directory and assigns it to the developers group, and installs the getfacl and setfacl utilities needed for Task 5. The last two commands are the verification the assignment calls for.

Expected output includes: acl 2.3.2-1build1.1 newly installed, id alice showing groups alice and developers, and /project listed at the root as drwxr-xr-x root developers.

Screenshot: 01-lab-setup

Status: Complete.

## Task 1: Permission Audit

```
mkdir ~/cvnp1601-portfolio/week04-access-lockdown
cd ~/cvnp1601-portfolio/week04-access-lockdown
{ ls -la /etc/shadow /usr/bin/passwd /tmp /project; umask; } > permission-audit.txt
cat permission-audit.txt
```

Creates the week folder and moves into it so the audit file is written there, then captures the permission strings for the two files and two directories, plus the current umask, into a single file and displays it.

Expected output includes: -rw-r----- root shadow on /etc/shadow, -rwsr-xr-x root root on /usr/bin/passwd, drwxrwxrwt on /tmp, drwxr-xr-x root developers on /project, and a umask of 0002.

Screenshot: 02-permission-audit

Status: Complete.

## Task 2: chmod and chown

```
touch ~/deploy.sh
ls -la ~/deploy.sh
chmod 750 ~/deploy.sh
ls -la ~/deploy.sh
sudo chmod g+w /project
sudo chown $(whoami):developers /project
ls -ld /project
```

Creates a new script file and records its default permissions, restricts it to 750 and records the result, then adds group write to the shared directory and transfers ownership to steelbyte while keeping the developers group.

Expected output includes: -rw-rw-r-- on deploy.sh before and -rwxr-x--- after, and /project as drwxrwxr-x steelbyte developers.

Screenshot: 03-chmod-chown

Status: Complete.

## Task 3: Sticky Bit

```
sudo chmod +t /project
ls -ld /project
sudo -u alice touch /project/alice-file.txt
sudo -u bob rm /project/alice-file.txt
ls -la /project
```

Sets the sticky bit on the shared directory, creates a file as alice, then attempts to delete that file as bob and confirms it is still present. The rm prompts first because the file is not writable by bob, and the prompt was answered y.

Expected output includes: drwxrwxr-t on /project, the prompt rm: remove write-protected regular empty file '/project/alice-file.txt'?, the error rm: cannot remove '/project/alice-file.txt': Operation not permitted, and alice-file.txt still listed as -rw-rw-r-- alice alice.

Screenshot: 04-sticky-bit

Status: Complete. The delete was denied as expected.

## Task 4: SGID

```
sudo -u alice touch /project/before-sgid.txt
ls -la /project/before-sgid.txt
sudo chmod g+s /project
ls -ld /project
sudo -u alice touch /project/after-sgid.txt
ls -la /project/before-sgid.txt /project/after-sgid.txt
```

Creates a file as alice before SGID is set and records its group owner, sets SGID on the shared directory, then creates a second file as alice and compares both group owners side by side.

Expected output includes: before-sgid.txt as -rw-rw-r-- alice alice, /project as drwxrwsr-t, and after-sgid.txt as -rw-rw-r-- alice developers.

Screenshot: 05-sgid

Status: Complete.

## Task 5: ACL Configuration

```
getfacl /project >> acl-audit.txt
sudo setfacl -m u:carlos:r-x /project
getfacl /project >> acl-audit.txt
sudo setfacl -d -m g:developers:rw /project
getfacl /project >> acl-audit.txt
touch /project/acl-test.txt
getfacl /project/acl-test.txt >> acl-audit.txt
sudo setfacl -x u:carlos /project
getfacl /project >> acl-audit.txt
```

Records the baseline ACL, adds a named user entry giving carlos read and execute, adds a default ACL granting the developers group read and write, creates a test file to show inheritance, removes the carlos entry, and records the ACL after every step. All getfacl output is redirected into acl-audit.txt, so the screen shows the commands and the getfacl notice about the leading slash while the ACL content lands in the file.

Expected output includes, in acl-audit.txt: a baseline with flags -st and no named entries, user:carlos:r-x with mask::rwx in the second and third snapshots, default entries including default:group:developers:rw- in the third, group:developers:rw- inherited on acl-test.txt with mask::rw- capping group::rwx to an effective rw- in the fourth, and no carlos entry in the fifth.

Screenshot: 06-acl-configuration

Status: Complete. Carlos's access was granted and then fully revoked.

## Task 6: Break/Fix Diagnostic

Paper exercise. No commands were run on the VM. The full four section answer is in week4-diagnosis.md.

Status: Complete.

## Task Explanations

### Task 1: Permission breakdowns and umask

/etc/shadow is -rw-r----- owned by root with group shadow. The leading dash indicates that this is a regular file. The owner portion rw- allows root to read and write. The group portion r-- allows the shadow group to read, but does not allow them to change the contents. The others portion --- provides everyone else with nothing. There are no special bits associated with this file. It contains the password hashes for each account on the machine. Therefore, limiting access to the file limits the ability of anyone other than root to copy these hashes and crack them offline.

/usr/bin/passwd is -rwsr-xr-x owned by root with group root. As previously indicated, the leading dash shows that this is a regular file. The owner portion rws permits root to read, write, and execute. The lower case 's' in rws also indicates that the setuid bit is turned on in addition to permitting execution. The group portion r-x allows members of the root group to both read and execute. The others portion r-x allows any user to execute. Therefore, since the setuid bit is turned on, changing your own password lets you write to /etc/shadow, which only root can do; setuid causes the program to run as its owner instead of the user who started it.

/tmp is drwxrwxrwt owned by root with group root. The 'd' at the beginning indicates that this is a directory. All three portions, owner, group, and others, have rwx permissions, and the lower case 't' at the end indicates that the sticky bit is turned on in conjunction with giving execute permission to others. Although every user requires a location to temporarily place their files, we want this directory to be available to all users. The sticky bit is used to prevent one user from deleting or renaming another user's file.

/project is drwxr-xr-x owned by root with group developers. The 'd' at the beginning indicates that this is a directory. The owner portion rwx grants root complete control over the directory. The group portion r-x grants the developers group list and enter into the directory, however it does not grant them create or delete privileges. Similarly, the others portion r-x grants any other user the ability to perform the same actions. No special bits are present within this directory entry. At this point in time prior to making any of the changes suggested by the tickets, neither the team nor any other user can write; there is no protection against deleting files created by either the team or any other user; and newly created files would not inherit the developer group.

My current umask is 0002. In an umask value, a leading zero represents the special bits. When creating a new file, it begins at 666. The umask then turns off those bits that it sets, so I lose write capability in the others portion. Subsequently, 666 with 002 removed = 664, which equates to rw-rw-r--, where the owner and group receive read and write capabilities, while others receive only read capabilities.

### Task 2: Octal 750

Each number is a combination of permissions: read at 4, write at 2, and execute at 1. Owner = First Number: read, write, execute; Group = Second Number: read, execute; Everyone else = Third Number: none. 7 = Read + Write + Execute = Owner has all. 5 = Read + Execute = Only Group members can run, not modify. 0 = None = Other users have zero access to the file, not even reading. So, when I am running deploy.sh, I can edit and run the script; users in my group can run it, but they cannot alter it; and all other accounts on the server can't open the file to view its contents. This makes sense because most scripts reference locations, server names, etc., which should never be available for every user to view.

### Task 3: Why the sticky bit protects shared directory integrity

Write permissions for a directory determine which members of your team may be able to add files and/or delete/rename existing files. Those same permissions apply to all files within a given directory, regardless of ownership. For example, if you have a shared directory such as /project with write permissions granted to the developers group, then each developer, such as Bob, will have the ability to delete or rename another team member's files. When the sticky attribute is applied to a directory, the rules are modified so that only the owner of the file, the owner of the directory, or root will be able to delete or rename an entry in that directory. This is what happened in Bob's case. Because he is a member of the developers group and therefore has group write permissions on /project, when he ran rm alice-file.txt, he got an Operation not permitted error, yet the file remained intact. If this were a different type of command, for example, instead of removing the file, if it were deleting its entire contents, it could result in losing not just one individual's data, but the collective data from the entire team.

### Task 4: SGID for team collaboration

If you don't set SGID on your shared directory, users who create new files in it will own those files under their own group. So if Alice creates a file and Bob creates a file, then Bob can edit his file but he can't modify Alice's file even though they are both members of the developers group. This happens because the default behavior is to assign new files to the group of the user who created them. That is why every new file would belong to either Alice's group or Bob's group. So the developers group has no control over these files. To make sure files go into the group that should have access, you need to use SGID on the directory. When you do that, it makes all new files inherit the group of the directory where they're created. This is shown here as well. Before I ran chmod g+s on my /project directory, before-sgid.txt had group alice. After I did that, after-sgid.txt had group developers. The normal way of getting around this problem without using SGID is for everyone involved to run chmod manually on each file. Or, worse, open permissions for all users in the group since that is easier than fixing the groups on all the files.

### Task 5: When ACLs are better than standard group permissions

One of the main issues with standard permissions is that they allow only one group and one owner, so all other permissions are handled through group membership. Group membership is the wrong tool for a single, short-term exception. For example, as a contractor, Carlos requires read-only access to the project directory for a period of time. When I add Carlos using usermod -aG, he will now have complete developer group access, including to directories outside of /project. Additionally, if I forget to remove him at the end of his contract, someone will still be responsible for removing his developers group membership. On the other hand, when I use setfacl -m u:carlos:r-x , I am granting the exact same level of access requested by the ticket only to /project. I also provide an audit trail since this information is visible in the output of getfacl. Finally, since this ACL was created using setfacl -m, it may easily be removed in a single command with setfacl -x.

## Troubleshooting Notes

No deviations from the assignment occurred this week. Every command ran as written and produced the expected output, including the denied delete in Task 3 and the ACL inheritance and removal in Task 5. The troubleshooting narrative for this week addresses the realistic failure the ticket describes rather than one encountered during the lab.

## Portfolio Card

I audited and corrected the access controls on a shared Linux directory with the sticky bit, SGID, and ACLs, giving a development team the access they need and an administrator a clean way to revoke temporary access later.

## AI Use Statement

I used Claude as an assistant while doing the assignment. I performed all commands shown in this folder on my own virtual machine. All of my screenshots are my own output. I completed the audit, changed permissions, added the sticky bit and SGID, and manually created ACLs. Once complete, I took the completed results and pasted them for the AI to check for accuracy and correctness.

I used the AI to find technical errors in what I was writing and chose which corrections to make. The AI found several actual technical errors that I made in writing, including incorrectly identifying which ACL entry went to the directory versus which went to the test file.

The AI provided me with the original sources it used to perform its tasks, so I could verify everything it said about those sources.

I fact-checked all technical claims it made using the man pages for chmod, rm, sudo, and getfacl instead of relying on what the AI said as fact.

## Files In This Folder

- README.md
- permission-audit.txt
- acl-audit.txt
- tech-lead-note.md
- troubleshooting-narrative.md
- week4-diagnosis.md
- evidence-report.txt
- collect-evidence.sh
- screenshots/
