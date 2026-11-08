Troubleshooting Narrative

What could have gone wrong, What actually did go wrong
If I had taken the cron entry provided in the assignment, /home/student, as the path for the script and logs, instead of taking the time to enter them manually using my own home directory path, cron would have attempted to execute a non-existent script, and attempt to log messages to a directory that didn't exist. As a result, the job would have failed every day, but since cron runs in the background with no terminal, nothing would have appeared on my screen.
In addition to incorrect paths being used, if there was an issue with the scheduled time, and/or if my VM's clock wasn't set correctly, and/or my VM's clock doesn't sync properly, cron jobs are executed based upon the server's time zone, which on this VM is UTC. Therefore, a cron job set for 0 6 * * * would be executed at 6:00 am UTC time, not 6:00 am central time. This could potentially cause issues depending upon how you've configured your reports.

What I checked First
First, I reviewed the output from task 2 via ls -la which displayed the full path to my script located under my own home directory; secondly, I reviewed the output from task 3 regarding the report path printed out by the manual run; thirdly, I reviewed the Date line within my report header, which indicated the server was running off of the UTC timezone.

What I Tried
Before I even let cron touch it, I first ran my script by hand just to make sure it ran as expected. Secondly, I constructed my cron entry with the absolute paths from my own system rather than the sample paths included in the cron example. Finally, I retained the PATH line so that cron can locate df, free, vmstat and ss.

What Fixed It - Or What I Would Try Next
Since I had already identified and corrected the path problems prior to allowing cron to access my scripts, the use of my true absolute paths in my cron entry resolved this potential problem. If a scheduled report ever failed to appear, I would verify that the job was still scheduled by reviewing crontab -l. Then, if necessary, I would review ps to determine whether a previous cron run became hung. Additionally, I would review the cron log for any errors that may have occurred during execution.

How Did I Verify My Results?
Upon successfully executing the manual run of my script, I visually confirmed that a report file existed. Then, after verifying that file existed using ls -la ~/reports, I utilized tail to view all lines contained within that file. After confirming that the report file had a valid hostname and date header, I verified each subsequent labeled section utilizing grep. Lastly, I confirmed that my crontab -l was populated with both the PATH line and the 0 6 * * * entry referencing my specific paths.

Security/Reliability Impact
cron jobs will simply fail if they reference a path that is invalid. However, because of how cron handles errors, it writes failures into a local mail spool, most users will never know that their job has failed. As such, most people will simply assume that their server is operating as expected. In many cases, silent failure like this results in serious issues going undetected. For instance, if one of your servers runs low on disk space or stops providing services due to some other reason, it's possible that these types of issues could go completely unreported for extended periods of time due to silent cron job failures.
