State

The trainee's client did its part. The ssh -v command output showed that the client provided a public key in the /home/trainee/.ssh/id_ed25519 location; the key file existed and had been submitted to the server. However, the server failed to approve the client's use of the public key. Instead, the server indicated to the client that additional public key and/or password-based authentications were possible but ended with Permission denied publickey, password. The ls -la command output also confirmed that the .ssh directory drwx------ and authorized_keys -rw------- files are both owned by user student; these two items match the requirements listed in the checklist. Finally, the transcript included information from auth.log regarding the reason why sshd rejected the client's authentication request: Authentication refused: bad ownership or modes for directory /home/student. An additional piece of information from the transcript shows that because the server does list password-based methods as being acceptable, password-based authentication is currently enabled on this server.

Root cause

The home directory /home/student is probably owned or configured insecurely because it was set to be writable by the group or others at some point. When you generate a public/private SSH key pair using SSH client software, that client software also generates the private key and writes both keys to your local computer's files. The SSH server, which listens for incoming SSH connections, performs safety checks on three items prior to trusting the SSH key file: A) the home directory; B) the .ssh directory; C) the authorized_keys file located within the .ssh directory. If the home directory is writable by anyone other than yourself, there may be a different login account that will replace .ssh with their own .ssh or place their own public key into authorized_keys. Therefore, when the SSH server checks the key file, it will always refuse to trust the authorized_keys file because it is located inside a home directory that others can write to, even though the file and the .ssh directory are still correct. The key file is not corrupted and SSH keys do not expire, so regenerating the key pair would not fix the problem, because the same home directory check would fail again.

Remediation

The first fix was to revoke write permissions for groups and other users on the home directory using: sudo chmod go-w /home/student. If running ls -ld /home/student produces a listing showing that the directory owner is something other than student, then ownership of the directory needs to be restored to student. Since the server still allows password login, the trainee can use either their password or console access to apply the fix.

Verification

The first angle is the filesystem: The output from ls -ld /home/student should be the student directory that has no write access for group and other users; for example, drwxr-x---.

The second angle is the daemon: An attempt at logging into the server via ssh -v student@SERVER_IP using the student's SSH key should authenticate as before rather than ending with a Permission denied message; tail /var/log/auth.log will have an Accepted publickey for student entry but no new entries saying Authentication refused.

Security note

A checklist listing only .ssh and authorized_keys would be insufficient, because the SSH daemon also checks each directory along the path. Improperly set permissions on a directory above an otherwise properly configured .ssh/authorized_keys pair can cancel all the work you did on those two files. Security checking of SSH keys will require reviewing all directories in the path to the files in question. Furthermore, if there are issues with the directories in this path, sshd will log the specific directory that caused the issue, which is much faster and safer than guessing which key might be the problem.
