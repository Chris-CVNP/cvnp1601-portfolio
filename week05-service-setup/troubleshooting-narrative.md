Week 5 Troubleshooting Narrative

1. What went wrong, or what could realistically have gone wrong?

During Task 1 I ran dpkg -l nginx twice in a row and skipped the purge command that was supposed to run between them. Both outputs showed ii, so my removed-state check was really a second copy of the installed state. If I had taken the screenshot without reading it, the evidence for the removal would have proved the opposite of what it claimed.

2. What evidence did you check first?

I checked the status column in the second dpkg -l output. It still read ii with version 1.24.0-2ubuntu7.18, which meant nginx was still installed. I then went back through my terminal history and saw that sudo apt purge nginx && sudo apt autoremove -y never appeared between the two dpkg -l commands.

3. What did you try?

I ran the purge and autoremove line, answered Y at the purge prompt, and let autoremove finish before running dpkg -l again.

4. What fixed it, or what would you try next?

Running the command I had skipped fixed it. apt removed nginx, and autoremove then removed nginx-common along with two unrelated orphaned packages, libfwupd2 and libgusb2.

5. How did you verify the result?

I ran dpkg -l nginx again and the status changed from ii to un, meaning the package was no longer installed. That output is the one I used for the removed-state screenshot.

6. What was the security or reliability impact of the issue or fix?

The missing step was a reliability issue. The evidence that did not support the claim created the impression that the removal had occurred completely when in fact it hadn't been done at all. Also, the fix for this error has uncovered an additional risk associated with autoremove -y. This option will remove all orphan packages from the entire system as opposed to only those related to the package being purged. Therefore, if you are working in a production environment, you would want to use autoremove, but do it without the -y flag initially to review the list prior to removing any items.
