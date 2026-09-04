# Week 2 Break/Fix Diagnostic

## State

The awk command worked in the sense that it printed the "$11"; it failed in that it printed every "$11" in the auth.log, since there was no | grep to limit which IP addresses it pulled. The word count worked correctly. The uniq command did not work as intended because it was given unsorted input, not because uniq is faulty. There was no | sort included before it, so there was no way for uniq to properly count the IP addresses. The trainee was expecting to see 3 10.0.0.5, but he did not give the correct command to get that as an output.

## Root cause

uniq -c only counts duplicate lines that are adjacent to each other, and the input file is in log order so identical addresses are scattered rather than grouped. Since uniq ran before sort, there was only one for it to count at a time before a different IP address was next in the count order which reset the count to one. Unless, by chance, there were two or more next to each other naturally, you would never get a count of more than one. That's why in this case sort needed to be before uniq. The pipeline does contain a sort, but it runs after uniq on output that is already wrong, so it only reorders bad numbers into a tidy descending list.

## Remediation

sort src-ips.txt | uniq -c | sort -rn | head -5

The input is sorted before it reaches uniq, so identical addresses land adjacent and uniq can collapse them into one line per address with a true total. The first sort groups the lines, the second sort ranks the results by count.

## Verification

First, rerun the corrected pipeline and confirm each address now appears on a single line with a real total, ordered highest first.

Second, count one address independently without sort or uniq, using awk to tally into an array:

awk '{count[$1]++} END {for (ip in count) print count[ip], ip}' src-ips.txt | sort -rn | head -5

When both command methods produce the same result it verifies the count. Since the two methods reach the answer through different routes and do not depend on each other, agreement between them substantiates the result.

## Security note

If you ship a false or unverified count you are giving inaccurate information that can drive the next steps in the wrong direction. Garbage in, garbage out. It can either show there is no problem and mask one that exists, or the reverse, show a problem where there is not one. In the trainee's report, a flat count of 1 and 2 across every address hides that one source is showing up repeatedly, which is the exact thing the report was built to surface.
