# CVNP1601 Week 11: SSH Log Analysis Report

Ticket: CVNP1601-W11-011

## Objectives

- Confirm the SSH log source with journalctl and /var/log/auth.log
- Filter auth.log for failed password events and count them
- Verify the awk field that holds the source IP before using it
- Build the ranked attack pipeline and compare it to the broken version without the first sort
- Write a security-focused analysis summary, technical lead note, and break/fix diagnosis

## Tools Used

- journalctl
- ls
- sudo
- tail
- grep
- awk
- sort
- uniq
- head
- wc
- date
- sed
- cp
- mkdir
- git

## Configuration

### Ticket Information

- Ticket ID: CVNP1601-W11-011
- Submitted by: Security operations lead
- Affected system: SSH daemon, systemd journal, and /var/log/auth.log
- Reported issue: Possible brute-force SSH activity needs review
- Business impact: Medium
- Required outcome: Failed SSH activity counted, top source IPs ranked, pipeline explained, and security note written

### Scenario Summary

The security operations lead asked for a review of SSH authentication failures on VM 102, hostname 1601, Ubuntu Server 24.04 LTS on Proxmox. The lead wanted a short report with the failed password count, the top source IPs, and the command evidence behind the conclusion. Every assignment command was run as written. The current auth.log contains no Failed password entries, so the counts and pipelines returned 0 or no output, and that result is documented and explained below.

## Task 1: Confirm Log Sources

```
journalctl -u ssh --no-pager -n 100
```

Shows the last 100 journal entries for the ssh unit as plain text.

Expected output includes: sshd start and stop events and SSH login entries.

Result: Entries returned, including server listening on port 22 and Accepted publickey logins from 10.10.65.11. Screenshot: 01-ssh-journal

```
journalctl -u sshd --no-pager -n 100
```

Same query using the sshd unit name.

Expected output includes: either SSH entries or No entries, depending on the system's unit name.

Result: No entries. The unit name on this VM is ssh. Screenshot: 01-ssh-journal

```
ls -la /var/log/auth.log
```

Lists auth.log with its permissions, owner, size, and date.

Expected output includes: the auth.log file entry.

Result: Not included in the screenshot. See Troubleshooting Notes, Issue 3.

```
sudo tail -50 /var/log/auth.log
```

Shows the last 50 lines of auth.log.

Expected output includes: recent authentication entries.

Result: Returned CRON session entries, one Accepted publickey login, and the sudo entry for this command, confirming auth.log exists and is current. Screenshot: 02-auth-log-listing-tail

Status: Complete.

## Task 2: Filter Failed Password Events

```
grep "Failed password" /var/log/auth.log | head -20
```

Prints the first 20 Failed password lines.

Expected output includes: Failed password lines with a username, source IP, and port.

Result: No output. Screenshot: 03-failed-password-first-lines

```
grep -c "Failed password" /var/log/auth.log
```

Counts the Failed password lines.

Expected output includes: a single number.

Result: 0. Screenshot: 04-failed-password-count

```
grep -E "Failed password|Invalid user" /var/log/auth.log | head -20
```

Matches either pattern in one pass.

Expected output includes: Failed password and Invalid user lines.

Result: No output. Screenshot: 05-multi-pattern-search

```
grep -v "Failed password" /var/log/auth.log | grep "sshd" | head -10
```

Shows sshd lines that are not failures.

Expected output includes: other sshd activity in the log.

Result: Two sshd lines, an Accepted publickey login from 10.10.65.11 and its session opened entry. Screenshot: 06-exclusion-search

Notes on the grep flags:

-c tells grep to count the matching lines and print only the total instead of the lines themselves. On this VM it returned 0.

-E turns on extended regular expressions, so the pipe symbol works as OR between patterns without escaping it. This let one grep search for Failed password and Invalid user in a single pass.

-v inverts the match and prints only the lines that do not contain the pattern. Piping that into grep sshd showed the other SSH activity in the log, which on this VM was successful public key logins.

Status: Complete.

## Task 3: Verify awk Field Positions

```
grep "Failed password" /var/log/auth.log | head -5
```

```
grep "Failed password" /var/log/auth.log | head -5 | awk '{print NF}'
```

```
grep "Failed password" /var/log/auth.log | head -5 | awk '{print $11}'
```

```
grep "Failed password" /var/log/auth.log | head -5 | awk '{for (i=1; i<=NF; i++) print i ":" $i; print "---"}'
```

Shows the sample lines, the field count, field 11, and a numbered map of every field.

Expected output includes: the field count and the field holding the source IP.

Result: No output from any of the four commands. Screenshot: 07-awk-field-verification

The four commands run without error, however, none produced output. The auth.log on this virtual machine has no entries for Failed password. So the grep command found nothing to send to awk. Therefore, awk did not find anything to perform its field counting operation on. Consequently, there was no data for NF, the $11 print, or the loop that counts field position to produce any results.

Even though there were no failed lines to test, I am able to identify where the source IP would be based upon the format of my own log. This virtual machine stores timestamps in a high precision format, such as 2026-11-04T00:10:20.733174+00:00. However, the older format stored the date as month, day, and time, which is three fields. Therefore, when I determine the fields used in a successfully completed sshd login entry in my log, I find that field 1 contains the timestamp, field 2 contains the name of the host, field 3 contains the sshd process tag, and the IP address falls at field 9, after the word from.

Similarly, if a Failed password line contained the same type of information, then it too would follow this same pattern; therefore, it would have an NF value of 12 and the source IP would be located at field 9. If you use awk with $11, then it would print the port number rather than the IP. For an invalid user line, it will add two words to precede the username. Therefore, an invalid user line would have an NF value of 14 and shift the IP into field 11. These values represent the fields of my own log's format, and were not tested against an actual failed login entry. That is why the field-count loop is important to me prior to relying on any field numbers.

Status: Complete.

## Task 4: Build the Ranked Attack Pipeline

```
grep "Failed password" /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -rn | head -10
```

Correct pipeline: filters failures, extracts the IP field, groups, counts, and ranks the top ten.

```
grep "Failed password" /var/log/auth.log | awk '{print $11}' | uniq -c | sort -rn | head -10
```

Deliberately broken version without the first sort.

Expected output includes: a ranked count per IP from the correct version, and split, smaller counts from the broken version.

Result: No output from either pipeline. Screenshot: 08-ranked-and-broken-pipeline

The two pipelines both completed successfully and were able to provide no results because neither pipeline had a single Failed password line in auth.log to track for those pipelines.

uniq -c will only combine identical lines that immediately follow each other. So the first sort needs to group all copies of the same IP into groups that uniq -c can then count as such. In the correct pipeline, each IP should have shown up exactly once with its entire total, meaning how many times the IP attempted to log in, followed by a final sort -rn that ranks the entries from highest to lowest based on their attempt totals. In the incorrect pipeline, each appearance of an IP throughout the log would be counted individually; therefore, instead of showing up once per IP with its actual total, it may show up multiple times with low totals. The erroneous data is difficult to detect because the erroneous data will look very much like legitimate IPs and legitimate totals.

Status: Complete.

## Task 5: Analysis Summary and Cheat Sheet

Week 11 entries were appended to the master cheat sheet at ~/week1-cheatsheet.txt with a heredoc: journalctl -u ssh, grep -c, -E, -v, awk field numbering and NF, the attack-count pipeline, and the sort | uniq -c | sort -rn pattern.

```
sed -n '/Week 11 Command Cheat Sheet/,$p' ~/week1-cheatsheet.txt
```

Displays the Week 11 section of the cheat sheet.

Expected output includes: the Week 11 header and all five entries.

Result: All five entries displayed. Screenshot: 09-week11-cheatsheet-entries

The analysis summary is in attack-summary.md. A snapshot of the master cheat sheet is committed in this folder.

Status: Complete.

## Assignment Bridge Items

The Week 11 Assignment Bridge called for three checks not listed in the assignment tasks.

```
grep "Failed password" /var/log/auth.log | wc -l
```

Counts Failed password lines with wc -l. Result: 0.

```
grep "Failed password" /var/log/auth.log | awk '{print $11}' | sort | uniq -c | sort -rn | head -10 > ~/cvnp1601-portfolio/week11-ssh-log-analysis/ssh_ranked_$(date +%Y%m%d_%H%M%S).txt
```

Saves the ranked output to a timestamped file. Result: ssh_ranked_20261104_013601.txt was created at 0 bytes.

```
grep "Failed password" /var/log/auth.log | awk '{print substr($1,1,13)}' | sort | uniq -c
```

Counts Failed password lines per hour from the timestamp field. Result: No output.

Status: Complete.

## Task 6: Break/Fix Diagnostic

Paper exercise. No commands were run on the VM. See week11-diagnosis.md.

## Evidence Collection

```
cd ~/cvnp1601-portfolio/week11-ssh-log-analysis
sudo -v
bash collect-evidence.sh
cat evidence-report.txt
```

Refreshes the sudo timestamp, runs the Week 11 evidence script from inside the week folder, and displays the report.

Expected output includes: every required file shown as FOUND.

Status: Complete.

## Troubleshooting Notes

### Issue 1

Command: grep -c "Failed password" /var/log/auth.log

Root Cause: The current auth.log contains no Failed password entries. Every SSH login recorded in both the journal and auth.log is an Accepted publickey login from 10.10.65.11, the internal workstation.

Resolution: Every assignment command was run as written, the empty results were captured, and each written answer explains what the commands would show if failed passwords existed.

Result: The count is 0, and the Task 2 searches, Task 3 field checks, and Task 4 pipelines returned no output.

### Issue 2

Command: grep "Failed password" /var/log/auth.log | head -5 | awk '{print $11}'

Root Cause: This VM logs high precision timestamps, such as 2026-11-04T00:10:20.733174+00:00, which awk reads as one field instead of the three fields in the older month, day, and time format. By count from a real sshd line in this log, the source IP on a Failed password line would be field 9, and $11 would print the port number.

Resolution: The assignment's field 11 commands were kept as written. The field position is documented in the Task 3 answer, the cheat sheet, and the technical lead note.

Result: No output, because there were no Failed password lines. The field 9 position is counted from this log's format and was not tested against a real failed line.

### Issue 3

Command: ls -la /var/log/auth.log

Root Cause: The listing output was not included in the Task 1 screenshot.

Resolution: The screenshot was not replaced. Task 1 evidence is the journal output in 01-ssh-journal and the auth.log tail in 02-auth-log-listing-tail, which meets the assignment's evidence line of output from the SSH journal or auth.log.

Result: sudo tail -50 /var/log/auth.log returned current entries, confirming auth.log exists and is readable.

## Privacy Note

Screenshots are redacted for the username and SSH key fingerprints. RFC 1918 addresses remain visible. Only the lines relevant to each task are shown.

## Portfolio Card

What I Can Do Now: I can analyze SSH authentication logs with journalctl, grep, awk, sort, and uniq, verify the correct field before extracting source IPs, rank failed login sources by frequency, and explain when the evidence does and does not support a security conclusion.

## AI Use Statement

I used Claude to research how sshd logs failed passwords and how Ubuntu 24.04 formats its log timestamps, discuss the best course of action moving forward with the assignment and how to proceed with no failed login attempts, and correct my answers for technical accuracy and grammar. I ran every command on my own VM and checked each result against the actual output, including the zero Failed password count, the empty pipeline results, and the timestamp format in auth.log. Without AI help, I can explain why sort has to come before uniq -c, and why the source IP on this VM would be in field 9 instead of field 11 because the high-precision timestamp is a single field.

## Files In This Folder

- README.md
- attack-summary.md
- week11-diagnosis.md
- tech-lead-note.md
- troubleshooting-narrative.md
- week1-cheatsheet.txt
- ssh_ranked_20261104_013601.txt
- collect-evidence.sh
- evidence-report.txt
- screenshots/01-ssh-journal.png
- screenshots/02-auth-log-listing-tail.png
- screenshots/03-failed-password-first-lines.png
- screenshots/04-failed-password-count.png
- screenshots/05-multi-pattern-search.png
- screenshots/06-exclusion-search.png
- screenshots/07-awk-field-verification.png
- screenshots/08-ranked-and-broken-pipeline.png
- screenshots/09-week11-cheatsheet-entries.png

Note: evidence-report.txt was edited after collect-evidence.sh ran to redact the username and SSH key fingerprint, matching the screenshot redaction standard. No other content was changed.
