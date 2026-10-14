What went wrong or could have gone wrong
There were two potential problems with this job. First, there was the time. My local clock was five hours behind the log timestamps. This means the schedule would not run when I thought it should. Second, there was the test schedule. If I did not remove the */2 * * * * from the crontab, the script would continue to run every two minutes. It would generate roughly thirty reports per hour into the log.

Which evidence did I check first?
After completing my manual run of the script, I checked the script's log. The timestamp for this entry indicated that it occurred at 12:10 AM, 00:10:01, on October 14th; however, my local clock indicated that it was 7:10 PM on October 13th.

What did I try?
I compared this information to the syslog entries for my cron runs. All of the syslog timestamps contained +00:00, confirming that the VM clock operates based upon UTC. Since cron uses the server clock, the schedule will also be operated according to UTC.

What fixed it or what would I do next?
I chose to keep my last schedule as 0 6 * * 0 because it is required by the assignment, and I realized that it runs at 6:00 AM UTC, which equates to 1:00 AM Central. I used crontab -e to replace the test schedule with the weekly schedule. In the future, I plan on checking the server time zone using timedatectl prior to scheduling anything time-specific.

How did I verify that my fix worked?
The crontab -l command displayed only one line, the weekly line, and showed no */2 line. There were two scheduled entries at 00:26:01 and 00:28:01 in the script log, and two cron CMD lines at those times in the syslog. Also, the cron output log was blank.

Security and reliability impact
If a job is to run at a different hour than its team anticipates, they may experience busy hours or other maintenance schedules that may conflict with their own. If a test schedule is not properly removed from the crontab, it will waste disk space. Disk usage monitoring is exactly why I created this type of reporting tool. The timestamps within each of these logs allow anyone who views them to determine exactly when the job executed.
