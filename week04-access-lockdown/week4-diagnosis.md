# Week 4 Break/Fix Diagnostic

## State

In this example, three commands worked correctly, and one command produced unexpected output. The first two commands, chown and chmod u+s completed without any errors. Both the chown and chmod u+s also produced expected results. The first command changed the file owner to root, and the second added the setuid (u+s) bit to the file. The third command confirmed these changes by printing the permissions with ls -l, which showed -rwsr-xr-x, indicating that root is both the owner and group for the file; therefore, the setuid bit was successfully applied. However, the fourth command did not produce an expected result. This was because the user who created the file and executed the program was alice, but when she ran the script, it displayed Running as: alice instead of root. Even though all of the appropriate permissions had been assigned to allow the script to run with privileges, those privileges never actually took effect.

## Root cause

The file is a shell script and not an executable binary. Because of this, Linux ignores the setuid flag on scripts that begin with a shebang line and are handed off to an interpreter, so the operating system does not switch the running process to the file owner. When you run ls -l, you see the setuid flag present in the output from chmod, as it was written to the file's permissions field; at runtime, no mechanism uses it. So when you ran whoami, it returned alice since it is the user who invoked the script. This is intended behavior, not a chmod bug; even if you add the script to your /etc/sudoers file, this behavior will remain unchanged. They behave independently because setuid depends on file ownership, while sudo depends on a rule in sudoers matching the user who invoked the command.

## Remediation

The first thing you do is remove the setuid bit with chmod u-s backup.sh. This prevents the file from appearing to grant root privileges it can't grant. Also, since the trainee's approach doesn't match what the developers want, they should create a targeted sudoers entry. Use visudo to add a rule that lets the developers group run that one script by its full path as root, and validate it with visudo -c. This approach gives developers exactly the command they need to back up the system without granting general sudo access or relying on a bit ignored by the kernel.

## Verification

Beginning with the first angle: the policy. As a developer, you can run sudo -l to verify that the backup script will be listed by its full path in the output listing and nothing broader than that.

Second angle: the behavior. Run the backup script using sudo and confirm it produces Running as: root, after which confirm that a command outside the rule is still denied. The first shows what the policy said was correct; the second shows the boundary holds when running the program.

## Why the narrowest mechanism matters

The problem with this approach is that by fixing the wrong issue, we may find an easier solution than what the user needs. There are two ways to do this. First, you could add the developer(s) to the full sudo group so they can run the backup. That will make the backup run, but that will give them significantly more privileges than they requested. The second option is to create a wrapper binary and mark it as setuid(root). When a process is marked as setuid(root), all commands within that process run as root; if there is even one error in your wrapper script, it gives the hacker a path to a root shell. On the other hand, a single sudoer entry that specifies a specific command is both auditable and reversible. So getting someone escalated access to do their job is relatively simple. Getting escalated access to perform a very narrow function is actually where the real challenge lies.
