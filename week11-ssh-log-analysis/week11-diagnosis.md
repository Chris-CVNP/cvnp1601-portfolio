State:
The trainee executed two commands. Both read only /var/log/auth.log. The grep command used -c and returned 42 Failed password lines. The ranking pipeline split these 42 Failed password lines into 4 different IP addresses:
IP Address = 203.0.113.77; # of failed password attempts = 18
IP Address = 198.51.100.23; # of failed password attempts = 12
IP Address = 192.0.2.44; # of failed password attempts = 9
IP Address = 192.0.2.201; # of failed password attempts = 3.
Also the ls -la command displayed there are 4 different auth.log files. The size of the current auth.log file is 8214 bytes, and it was last updated on July 21st @ 9:12 AM. The next auth.log file, auth.log.1, had a size of 61802 bytes, and was last updated on July 20th @ 6:25 AM. auth.log.2.gz and auth.log.3.gz were last updated on July 13th @ 6:25 AM and July 6th @ 6:25 AM respectively. None of the older, rotated files were examined by the pipeline.

Root cause:
Log Rotation. The log files rotate once per week, and this occurs at the same time, every week. This time is 6:25 am, and it occurred on July 6th, July 13th and July 20th. So the current auth.log contains only the events that have been added to it since the last rotation date/time of July 20th, about 27 hours. The rest of the events from the week prior to July 20th are in the first rotated file, auth.log.1, which is roughly 7.5 times bigger than the current file and was not examined. Since the count of Failed password events covers only about a single day instead of the past week, the count does NOT indicate if the activity is increasing or decreasing.

Remediation:
Search every auth.log file, including the gzip'd ones. To find how many failed login attempts were recorded in each log file use zgrep -c "Failed password" /var/log/auth.log*. Then perform the same ranking operation as before but across all files.
To read both compressed and uncompressed files, you will need to use zcat -f. For example:
zcat -f /var/log/auth.log* | grep "Failed password" | awk '{print $11}' | sort | uniq -c | sort -rn | head -10

Verification:
Firstly verify the numbers. The sum of the individual file counts produced by zgrep -c should equal the count produced by zcat -f /var/log/auth.log* | grep -c "Failed password". If they do then every file was processed. Secondly verify independently. The systemd journal is kept separately from the text logs in /var/log. Therefore you may also want to use the system log data stored in the systemd journal and produce a count using journalctl -u ssh --since "7 days ago" --no-pager | grep -c "Failed password". As long as the systemd journal stores that amount of historical data, the counts from both sources should be similar for the same time frame.

Security note:
When looking for trends in attacks based solely upon activity contained within a single log file, please understand that a very small or diminishing number may actually be due to either the log file being relatively new or having just been created, therefore most likely containing little to no activity yet. All historical records regarding that specific time frame are located in older log files, in addition to potentially other areas such as firewall logs, Fail2Ban or even the systemd journal itself. Prior to passing along your findings to leadership and reporting a trend in attacks, ALL log records covering that time frame must be reviewed and counts must be compared among all logs covering that same timeframe. Failure to review and compare the counts among all relevant logs could result in reporting to leadership that an attack has ceased when it actually continues unabated.
