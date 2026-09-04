# CVNP1601 Week 02: Editing and Processing Text

## Portfolio Card

I used vim and nano to edit configuration files over a terminal session on a headless Linux server, and grep to read the active SSH settings.

## Note on the access report

The assignment builds the access report from Accepted password entries. This server had no successful password logins to report. The main sshd_config did not set PasswordAuthentication at all, and the setting was found in a cloud-init drop-in file that enabled it. Password authentication was disabled during this assignment and key authentication verified before the change was left in place. The report is built from Accepted publickey entries instead, using the same command structure with the field number corrected for this log format.

## AI Use Statement

AI was used in the following ways on this assignment. It drafted the Week 2 cheat sheet entries from the commands and findings in my own terminal work. It assisted with wording and technical accuracy on the written artifacts. It helped identify why a hardening drop-in file did not take effect after a service restart, which turned out to be a file load order issue. It helped identify that several lines in my first access report were sudo audit records matching the search string rather than actual login events.
