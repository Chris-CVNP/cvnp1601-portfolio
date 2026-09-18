What went wrong, or what could realistically have gone wrong?

There were no failures in this lab; however, the setup had the same issues described in the ticket. Initially, /project was created with permissions of 755 and owned by root, with developer group access allowed to read the contents; however, they did not have permission to create new files in the project. The realistic error occurs if someone uses chmod 777 to correct the ownership issue. This allows all accounts on the system to view and modify the directory's contents and does not fix the deletion issue or the group inheritance.

What evidence did you check first?

Before I made any changes to my system, I did a permission audit of what permissions existed so that I could see if there were any areas that would be an issue with my plan, in this case,/tmp versus /project. From the permission audit, I gathered details on each area, including ls -la on /etc/shadow, /usr/bin/passwd, /tmp, and /project, as well as the umask. The most important comparison for me was/tmp vs /project, since /tmp already had a sticky bit in its permission string and /project didn't have one.

What did you try?

Instead of changing everything with one command, I made incremental changes using individual controls. chmod g+w and chown provided developers with group write access. chmod +t enabled the setting of the sticky bit. chmod g+s provided SGID capability. Then, setfacl let me add named entries for Carlos, as well as a default ACL for all members of the developers group.

What fixed it, or what would you try next?

Each of these controls is going to prevent a unique type of failure. The group write allows users to create files in the directory; the sticky bit prevents another user from deleting their file; the SGID allows the group to inherit ownership when a file is created; and the ACL handles the contractor who does not have access to the directory through group membership. Next, I would check the others field for permissions, as it appears this directory has read and execute permissions.

How did you verify the result?

Each of my changes is supported by evidence, not assumption. The "t" and then the "s" appeared in the permissions string when I used ls -ld. When I tried to remove a file that belonged to Alice as user Bob, I got the error message "Operation not permitted," and the file remained intact. Before I set sgid on the directory, the file Alice created had its group set to Alice. After setting sgid, the next file Alice created had its group set to developers. Using getfacl demonstrated how Carlos had read and execute access on /project, how acl-test.txt inherited an entry for the developers group from the default ACL, and that Carlos's entry was gone from /project after I removed it.

What was the security impact of the issue or fix?

The fix maintained directory usability while limiting user access to what was needed for the task. By using a sticky bit, no single user's mistakes can destroy another user's files, maintaining data integrity. Using sgid ensures all new files created by users are created in the same group, preventing individual users from modifying permissions to read files they should not be able to view. With an ACL, the contractor was given read access to the directory, and if access needed to be removed, only one "setfacl" command is required, rather than removing them from the group.
