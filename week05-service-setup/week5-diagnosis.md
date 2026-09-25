Week 5 Break/Fix Diagnosis: nginx on web02

State

The install worked. apt finished with "Setting up nginx (1.18.0-6ubuntu14.4)" and dpkg -l nginx shows ii, which means the package is installed and configured correctly. What failed was the service step. sudo systemctl enable --now nginx returned "Failed to enable unit: Unit nginx.service is masked," so nginx was neither enabled for boot nor started. systemctl status nginx confirms it: the Loaded line reads masked and the Active line reads inactive (dead).

Root cause

The nginx.service unit is masked. Masking links the unit to /dev/null, which blocks every kind of activation, including enabling it and starting it manually. dpkg and systemctl are answering two different questions. dpkg reports on the package, and the package is fine. systemctl reports on the unit's state in systemd, and that is where the block is. Nothing in the transcript points to a corrupted install, and the error message names the actual problem.

Remediation

The first step is to remove the mask with sudo systemctl unmask nginx. After that, the trainee reruns sudo systemctl enable --now nginx to enable the service for boot and start it. Purging and reinstalling is not the fix. The reinstall targets the package, which the transcript already shows is fine, and it does not address the mask that systemctl named.

Verification

The first angle is the service manager. systemctl is-enabled nginx should return enabled instead of masked, systemctl is-active nginx should return active, and the Loaded line in systemctl status nginx should read loaded instead of masked. The second angle checks nginx from outside systemd by testing whether it is actually doing its job. curl -I http://localhost should return an HTTP response header from nginx, and ss -tln should show a listener on port 80. If both angles agree, the fix is confirmed.

Why reading the service manager output matters

A masked service does not crash or throw repeated errors. It just stays off quietly, so a service or safeguard the server depends on can be missing for a long time before anyone notices. In this case systemctl reported the exact cause in a single line. Jumping straight to a reinstall skips that evidence, spends time on a part of the system that was never broken, and leaves the real problem in place. Reading what the service manager actually reports leads directly to the one command that fixes it and keeps the server in a known state.
