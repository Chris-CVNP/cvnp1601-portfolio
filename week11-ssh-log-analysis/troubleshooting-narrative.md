What could have gone wrong with the analysis?
There may be some errors while defining the pipeline, such as the wrong log source, extracting the wrong field, ranking port number or username, etc. There can be a false sense of nothing happened based on an empty result due to a wrong file path, lack of permissions, or incorrect case usage within the grep expression.

What evidence did you check first?
First, I reviewed the log files. journalctl -u ssh produced results; however, journalctl -u sshd did not produce any entries. Additionally, /var/log/auth.log existed and could be read using sudo tail. This determined that the unit name on this VM was ssh, and that /var/log/auth.log was a viable source for the pipeline.

What did you try?
I executed all commands listed under Task 2 on /var/log/auth.log. grep -c produced 0; and the two searches for Failed password and Invalid user produced nothing. However, the exclusion using -v did provide sshd lines without the use of sudo, which eliminated a possible path or permissions issue. Each SSH login entry contained information about a successful Accepted publickey login from 10.10.65.11.

What fixed the pipeline?
None of the pipeline functions were damaged. There was no output because /var/log/auth.log contains no Failed password entries for processing. When reviewing the positional values of each field position, I discovered that this VM logs time stamps with high precision as one field; therefore, by counting, the source IP on a Failed password entry would be at field position 9 versus the field 11 utilized in the assignment.

How did you verify the result?
I validated my findings of the zero counts by utilizing both grep -c and multi-pattern searching. I also validated that the log file was accessible and current via the -v search and tail output, which displayed entries from the same session. I personally examined a successful sshd login line from my own log to determine how many fields are present and thus what position the source IP will occur.

What was the security impact?
Since no failed password attempts were identified, there were no attacking IPs to identify or escalate. All SSH access originated from my internal workstation through use of key authentication. The identification also demonstrated that if you were to utilize the assignment's field 11 pipeline on this VM without validation you would misidentify data when failed passwords begin to show up.
