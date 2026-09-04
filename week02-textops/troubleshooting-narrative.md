# Troubleshooting Narrative

## What did go wrong or could have gone wrong

When I looked through the active SSH config for Task 3, I noticed there were no settings for PasswordAuthentication within sshd_config. I assumed this server was completely key-based. A drop-in file created using cloud-init during provisioning had enabled password auth, and I had no idea it had been doing that the whole time.

## What I examined first

I used a double grep -v to see the active directives in sshd_config. There were 8 lines. The very first line was an Include statement directing me to /etc/ssh/sshd_config.d. I listed that directory and saw 50-cloud-init.conf. In my first attempt to examine it, I received nothing, so I thought the file was empty. The permissions on this file were set to 0600 (read/write owner), it belonged to root, and since 2>/dev/null had dumped the error message about permissions being denied, I didn't get anything back. Using sudo to view the file showed PasswordAuthentication yes.

## What I attempted

I created a drop-in called 99-hardening.conf. Within this file, I added lines to disable password authentication (PasswordAuthentication no) and enable public key authentication (PubkeyAuthentication yes). I tested the syntax of this file using sshd -t. Then I restarted the service. I then checked with sshd -T, which showed passwordauthentication was still yes.

## What corrected the problem

OpenSSH uses the first value it reads for a directive, and it reads drop-ins in filename order. Therefore, 50-cloud-init.conf was loaded prior to 99-hardening.conf and therefore prevailed. To ensure my drop-in loaded first, I renamed my file to be 01-hardening.conf. After validating once again, I restarted the service. I chose to rename the file instead of modifying the cloud-init file because cloud-init can overwrite files that it creates on subsequent boots; therefore, if I modified cloud-init's file, that modification could be overwritten on a future reboot thereby rendering my previous modifications useless.

## How I proved the correction

After restarting the service, I ran sshd -T and confirmed passwordauthentication no, pubkeyauthentication yes, and permitrootlogin no. sshd -T shows you the full resolution of your configuration after including all applicable include statements. That means it will show you what configuration the daemon is actually using versus what configuration may appear in individual configuration files. Next, I opened up a new session from another computer and confirmed that key authentication was working successfully before considering the changes to be complete.

## Security Implications

Password authentication was enabled on an internal device that I believed was key-only, secured with a lab-specific password, and reading one configuration file would never have revealed it. The failed first repair was the more significant aspect; the file was valid, syntax validated, and the service successfully started after restart. As such, all signals except for verifying the operational configuration indicated the update had been successful. Thus, if the operator assumes the system is secure in light of the perceived success of their actions, they are leaving the system exposed while believing it is hardened, which creates unnecessary risk to the organization.
