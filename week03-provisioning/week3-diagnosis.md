# Week 3 Break/Fix Diagnosis

## State

The trainee was able to create and log in to the contractor account, as shown by the execution of su - contractor and obtaining a shell prompt. So, the contractor account is defined in /etc/passwd with a valid shell and the trainee knows the password for the contractor account.

The file was created correctly and contained the correct data. The output of the command, sudo cat /etc/sudoers.d/contractor, was also the expected rule. Also, the ls -l command shows the file size to be 62 bytes and it is owned by root:root. What did not work was sudo itself. When the trainee ran the command, sudo -l as contractor, he received an answer stating that the contractor cannot run sudo on web03. That is not a "Denied Command" or a "Partial Grant", that is a message saying that sudo had no rules for contractor on web03. So, the contents of the file were never added to the policy.

## Root Cause

File Permissions. The ls -l command lists the file as -rw-r--r--, which translates to 0644. Files that are intended to be used by sudo under /etc/sudoers.d must be set to 0440. Each time that sudo includes a file in the policy, it checks both the ownership and permissions of that file. If either of those checks fail, it does not load the file into policy, regardless of whether a rule may exist.

This file became 0644 simply because nano created it with root's default umask value of 0022. visudo creates files with a mode of 0440 (and performs a syntax check) since visudo sets the default mode. visudo is the right way to go when creating drop-in files, not a generic editor.

The trainee only verified that he saw what he expected to see in the file using cat. There is no indication as to whether or not sudo will accept the file. The difference between your text being accurate and policy being applied is exactly why this happened.

The caching idea is wrong. Additionally, the transcript has already proven that it is wrong. Sudo looks at its policy each time it is invoked; there is nothing to clean out of cache. Trying to clean cache by rebooting would not change the mode of a file and would give the same error message.

## Remediation

First, fix the mode:

    sudo chmod 0440 /etc/sudoers.d/contractor

Second, the trainee could have done the following initial creation of his file (which establishes both correct mode AND runs a syntax check before creating the file):

    sudo visudo -f /etc/sudoers.d/contractor

## Verification

Independent Verification Techniques

There are two different ways to validate that the policy issue has been resolved separately.

The first technique is through validation of policy parsing. Running sudo visudo -c verifies the syntax, ownership and permissions of /etc/sudoers and of each drop-in file and reports back both where each failed (including file name and line number). The contractor file should now indicate that it was parsed ok versus failing due to bad permissions.

The second method is to test their effective privileges. Run sudo -l -U contractor from an administrative account to ask sudo what commands it believes the user is authorized to run. And then functionally prove this as contractor: the restart should succeed, and any additional systemctl actions attempted should fail.

These two techniques are independent because the first examines and parses policy files based on how a parser sees them, whereas the second method tests authorization functionally as a live user accesses sudo.

Therefore, if you only validate by one of these methods, you do NOT validate.

## Why Guessing Is More Harmful Than Checking

Files representing policy for sudo represent potential avenues of escalation for privilege attacks; to refuse trusting a file which does not satisfy ownership and permission requirements indicates good functioning of controls over trusting files as opposed to just another obstruction. A reboot would be wasting productive time, offer no evidence and incorrectly demonstrate to the trainee how sudo loads policy so that they will make the same mistake again on their next drop-in file.
