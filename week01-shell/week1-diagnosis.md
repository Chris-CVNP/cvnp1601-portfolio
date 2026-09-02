# Week 1 Break/Fix Diagnosis

## State

Both commands ran without issue. There were no errors returned by either command and the shell never indicated that something had failed.

The first grep searched the syslog file for any line containing "error" and redirected the results to the file named incident.txt. The subsequent wc command reported there were 215 lines within this file. So the first grep worked as intended.

The second grep searched the same syslog file for any line containing "critical", and also redirected the results to the same file name. The next wc command reported there were 3 lines. This represents the number of "critical" lines found. It does not represent any remaining lines from the original 215.

The commands ran without issue. However, the evidence file was compromised when those 215 "error" lines were overwritten upon execution of the second command, and there was no indication of this on the terminal screen.

## Root Cause

The second redirection was using a single arrow (>) versus a double arrow (>>) to redirect the output of the command to the file.

When you use a single arrow it deletes the contents of whatever file you are pointing it at and places your command's output into that empty file. It does this without warning you first that it will do so. So when the trainee typed the search for all instances of the critical term into the same named file as the previous one, the shell deleted incident.txt prior to grep producing a single line of output. Which means the trainee did not have access to the 215 error lines by then, because he deleted them.

This eliminates the possibility that it was the log rotation process that caused the loss of information. Since logrotate manages logs in /var/log, the trainee's creation of incident.txt in their home directory (/home/trainee) would be outside of logrotate's control.

If logrotate had truncated the source log partway through the capture, you would expect a partial or arbitrary count of records rather than the exact count of matching critical lines that a simple write over produces every time.

There is nothing here to escalate to the logging team.

## Remediation

The first thing to do is save what you can before running anything else and altering the state. incident.txt right now has the only copy of those 3 critical lines. Running the next command will destroy them if you do not think about this and preserve them first.

    cp ~/incident.txt ~/incident-critical.txt

The trainee should have used the append redirection on the second grep instead of the single arrow that cleared the file.

    grep -i "critical" syslog >> ~/incident.txt

If you want the complete evidence file assembled again you need to capture the errors again and then append the criticals on the end.

    grep -i "error" syslog > ~/incident.txt
    grep -i "critical" syslog >> ~/incident.txt

This only works because syslog still has all the original entries in it. If the original logs had already rotated by the time you got here, those 215 lines would be gone and the investigator would have a gap in their investigation which no amount of money or time could replace.

## Verification

You should perform these two types of checks for a couple reasons. One type of check alone might let an error through, but performing both will confirm that the file has the right amount of data in it and the right kind of data in it.

The first type of check is counting the results of each individual search as separate numbers and comparing those numbers to the number of lines in the file you created.

    grep -i "error" syslog | wc -l
    grep -i "critical" syslog | wc -l
    wc -l ~/incident.txt

If the first search returns 215 and the second returns 3, the file must contain 218 lines. If you get any number other than 218, then something has been overwritten, or something has been added twice.

The second type of check compares the data contained within the file; this can also help identify a problem that may have gone unnoticed in the line count. It is possible for a file to contain the correct number of lines and yet contain incorrect lines.

    grep -c -i "error" ~/incident.txt
    grep -c -i "critical" ~/incident.txt

Each of these counts has to match what its search returned against the log. Performing head and tail commands on the file provides visual evidence.

Because these two types of checks test different things about the same file, they are independent. For example, you could have 218 lines in a file, each of which contains only the word critical so there is no error data. In that case, the count check would pass, but the content check would immediately reveal the mistake.

## Security Stakes

The loss of any evidence you have already obtained as part of an investigation is significantly worse than simply starting over. Log data does not stay on the system forever. Rotation, retention limits, and disk space all clear entries out on a schedule, so the capture you took during an incident might be the only record those 215 lines ever existed. Once a log has been rotated off the system, an evidence file that has been overwritten cannot be restored.

This is also bigger than the one ticket. An incomplete evidence set leads to incorrect conclusions. A user who reports 3 critical events, while quietly deleting 215 error events, is giving their escalation team a representation of the issue that is false.

In regards to a security incident, the same oversight will destroy the chain of custody. Evidence which cannot be proven to be complete and unaltered is basically worthless during an investigation and in any subsequent legal proceeding.

There is no complicated way to develop habits that prevent this type of occurrence. Simply use append when adding to a collection, count the number of lines after each write, and stop what you are doing and investigate why the size of your output file decreased instead of increased before continuing.
