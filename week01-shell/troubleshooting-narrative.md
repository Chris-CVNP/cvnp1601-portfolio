# Troubleshooting Narrative

## 1. What went wrong, or what could have gone wrong?

The ticket said the application was throwing errors, but my search of the syslog returned zero matches. I honestly did not know which one was wrong. It could have been the ticket, it could have been my search, or I could have been looking in the wrong place. Without a larger data set it was hard to tell which of the two was incorrect, so I knew I needed to research more before reporting anything.

## 2. What evidence did you check first?

I checked syslog first. Besides being the first place to look, it is the root of the information and the place that holds the live data passing through the system, so it is the best place to find relevant information before going anywhere else. Before I searched anything I oriented myself with ls / to map the filesystem, ran pwd before and after every directory change, and used find to locate the log files under /var/log.

## 3. What did you try?

I ran wc -l on /var/log/syslog and got 3662 lines. A case-insensitive grep for error returned 0 matches. A grep for warning returned 14, and all 14 were the same DeprecationWarning from /usr/bin/unattended-upgrade under two process IDs. Then I searched the rotated log at /var/log/syslog.1, which had 8717 lines and 33 error matches.

## 4. What fixed it, or what would you try next?

Nothing was broken to fix. Next I would read the 33 matches in syslog.1 and check the application's own log directory. Then I would go back to the developer and ask them to walk me through it, tell me what they did and how they did it. There may be a key step in there that they did or did not do that could make all the difference. They may have done a step out of order, added a step, or missed one. They may have typed something incorrectly or been in the wrong directory when they were looking.

## 5. How did you verify the result?

I did not take the zero at face value. I checked the rotated log and got 33 matches, which showed the search worked and the current log genuinely had nothing in it. That also fit the state of the machine. The VM has roughly six hours of uptime since it was built and nothing running on it, so with mostly idle time, nothing being updated, and no input being made into the server, the likelihood of errors is low unless something is running in the background to cause them.

When I tried to list which processes produced those 33 matches, grep printed "binary file matches" and showed almost nothing. The count said 33 but the listing added up to 4. Those two numbers cannot describe the same search, which is what told me something was wrong. Grep had decided the file was binary and didn't display matches, even though it counted them all correctly. Adding the -a flag told grep to print them regardless of what it thought the file was, and the real search came back as 10 systemd, 4 multipathd, 4 kernel, and 2 each from two python3 processes. Running file on syslog.1 confirmed it was ASCII text the whole time, so grep's call was wrong.

## 6. What was the security impact?

Reporting a verified zero is defensible. Guessing at errors I never confirmed would have sent the development team after a fault this host has no evidence of. The grep issue is the same. If I had written down 4 processes instead of 10, I would have reported a number I never actually verified, and nothing in the output would have corrected me except one line I could easily have skipped over.

There is a saying, get good then get fast. Learning what you are doing and how to do it matters more than doing it fast. Something that takes 90 minutes with zero flaws is far more valuable than something that takes 60 minutes with seven flaws that you now have to find, locate, and correct. Taking the time to understand something is a valuable skill, and in evidence handling it is the difference between a report someone can act on and one that sends them in the wrong direction.
