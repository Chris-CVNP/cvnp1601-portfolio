# CVNP1601 Week 10: Network Connectivity Diagnosis
Ticket CVNP1601-W10-010

## Objectives

- Capture interface, route, and listening socket state before making any change
- Identify the failure layer by testing the interface, the default route, raw IP connectivity, and DNS separately
- Restore and verify routing with ip route add, ping, and traceroute
- Confirm sshd is listening on port 22 and explain connection refused versus connection timed out
- Capture post-fix state with the same command as the pre-change capture
- Diagnose a two default route break/fix scenario and name the route the kernel is actually using

## Tools Used

- mkdir
- ls
- head
- ip addr
- ip route
- ip route add
- ping
- traceroute
- apt
- ss
- grep
- systemctl
- ssh

## Configuration

### Ticket Information

- Ticket ID: CVNP1601-W10-010
- Submitted by: Service owner
- Affected system: Ubuntu VM networking, routing table, sshd, and listening sockets
- Reported issue: Server cannot reach external API endpoints
- Business impact: High
- Security consideration: Undocumented network changes make outages harder to audit and can accidentally expose services
- Required outcome: Pre-change state captured, root cause identified, fix applied, connectivity verified, and post-fix state captured

### Scenario Summary

The ticket reported a server that accepts SSH connections but cannot reach external endpoints. The work was performed on Ubuntu Server 24.04 running as VM 102 in Proxmox at 10.10.50.103, with commands run over SSH. The pre-change capture and the Task 2 tests showed the server was not broken at the time of testing: the interface was up with a DHCP address, a default route via 10.10.50.1 existed, raw IP and DNS tests both passed, and sshd was listening on port 22. The assignment's route fix was still run as directed, and its effect on the routing table is documented below along with the persistence warning.

## Task 1: Capture Pre-Change Network State

```
mkdir -p ~/reports
{ ip addr; echo "---"; ip route; echo "---"; ss -tlnp; } > ~/reports/network_$(date +%Y%m%d_%H%M%S).txt
ls -la ~/reports/network_*.txt
head ~/reports/network_*.txt
```

Creates the reports folder, captures interface state, the routing table, and listening sockets to one timestamped file before any change, then confirms the file exists and shows its first lines.

Expected output includes: ~/reports/network_20261028_163528.txt at 1409 bytes, and head showing lo and ens18 with inet 10.10.50.103/24.

Screenshot: 01-pre-change-capture

Status: Complete.

## Task 2: Identify the Failure Layer

```
ip addr show
ip route show
ping -c 4 8.8.8.8
ping -c 4 google.com
```

Checks the interface, the routing table, raw IP connectivity, and DNS resolution as four separate tests.

Expected output includes: ens18 UP with 10.10.50.103/24 dynamic, default via 10.10.50.1 dev ens18 proto dhcp metric 100, and 4 packets transmitted, 4 received, 0% packet loss for both pings, with google.com resolving to 192.178.157.113.

Screenshot: 02-failure-layer-check

Status: Complete. No failure found at any layer.

### Annotated Output

Interface: The ip addr show command displays that ens18 has been set in the up state, along with the flags UP and LOWER_UP, and that it has the UP state. Therefore, the interface has a link and is operational. ens18 is configured with the IP address 10.10.50.103/24, which was assigned by DHCP, as indicated by the dynamic flag. Since this is a valid IP address on the lab subnet, rather than a 169.254.x.x link-local address, DHCP successfully operated. The lo interface is only used for loopback traffic and therefore does not help determine if your traffic can be routed to the outside world.

Route: The ip route show command indicates that ens18 has a default route, i.e., to send traffic destined for other subnets, via 10.10.50.1, which was obtained through DHCP. In addition to the default route, there is a route for the local subnet, 10.10.50.0/24. A default route exists, so traffic for destinations that are external to your local subnet has a next-hop destination to which its traffic may be forwarded.

Raw IP Connectivity: ping -c 4 8.8.8.8 issued four packets and returned four packets; both were sent without any packet loss, a 100% success rate; the average round-trip-time was approximately 37.7 ms. Raw IP connectivity to the Internet works, which shows that routing is functioning properly.

DNS: ping -c 4 google.com resolved the hostname to 192.178.157.113 and returned four out of four successful responses without any packet loss. Therefore, resolving hostnames using DNS appears to be operating correctly, and there are no apparent problems associated with DNS.

Result: Your interface is operational; you have a default route; raw IP connectivity appears to function; and DNS functions appear to be normal. I did not see any failures at any layer on this server during my testing.

## Task 3: Restore and Verify Routing

```
sudo ip route add default via 10.10.50.1
ip route show
ping -c 4 8.8.8.8
ping -c 4 google.com
traceroute 8.8.8.8
```

Adds a default route through the lab gateway 10.10.50.1, then repeats the Task 2 connectivity checks and traces the path to 8.8.8.8. traceroute was not installed on the first run. See Troubleshooting Notes, Issue 1.

```
sudo apt install traceroute
sudo ip route add default via 10.10.50.1
ip route show
ping -c 4 8.8.8.8
ping -c 4 google.com
traceroute 8.8.8.8
```

Installs traceroute and reruns the full Task 3 sequence.

Expected output includes: RTNETLINK answers: File exists on the repeat route add, two default routes via 10.10.50.1 in ip route show, one with no metric and one proto dhcp at metric 100, 0% packet loss on both pings, and traceroute reaching dns.google in 11 hops with _gateway 10.10.50.1 as hop 1.

Screenshot: 03-route-and-connectivity

Status: Complete. ip route add is a runtime change only and does not survive a reboot. Persistent routing on Ubuntu normally belongs in netplan. See Troubleshooting Notes, Issue 2.

## Task 4: Diagnose Listening Ports and SSH

```
ss -tlnp
ss -tlnp | grep :22
sudo systemctl status ssh
ssh -v [REDACTED]@10.10.50.103
```

Lists listening TCP sockets, filters for port 22, checks the ssh service, and opens a verbose SSH connection to the VM. The username is redacted in this README.

Expected output includes: LISTEN on 0.0.0.0:22 and [::]:22, ssh.service active and running and enabled, and the ssh -v connection reaching port 22 with Connection established. See Troubleshooting Notes, Issue 3.

Screenshot: 04-ssh-port-22-listening

Status: Complete. sshd is listening on port 22 for IPv4 and IPv6.

### Connection Refused Versus Connection Timed Out

Connection Refused means that an SSH Client reached the Server, and Server replied to it by sending a TCP Reset to reject the connection. The host is reachable, and there's just no process listening for requests coming in through Port 22. This is often due to sshd, the ssh daemon, being stopped from running, or your firewall has been configured to reject incoming connections and reply accordingly.
A connection Timed Out means that an SSH Client sent its connection request, but received NO response whatsoever. Often times, this can be caused when a firewall drops the traffic without replying, you have an incorrect IP Address, or simply the target host is down/unreachable.
Refused indicates I should start my troubleshooting by checking if the SSH Service is actually Running on the Target Server. Time-out indicates I should go ahead and troubleshoot the Network Path and Firewall first. As seen above, an ss -tlnp will show us that sshd IS Listening on Port 22 for BOTH IPv4 & IPv6. Additionally, a systemctl status ssh command will confirm that the service IS active & running.

## Task 5: Capture Post-Fix State and Update Cheat Sheet

```
{ ip addr; echo "---"; ip route; echo "---"; ss -tlnp; } > ~/reports/network_postfix_$(date +%Y%m%d_%H%M%S).txt
ls -la ~/reports/network*.txt
```

Captures the post-fix state with the same command pattern as Task 1 so the two files compare directly, then confirms both timestamped files exist.

Expected output includes: network_20261028_163528.txt at 1409 bytes and network_postfix_20261028_172947.txt at 1443 bytes.

Screenshot: 05-post-fix-capture-files

Status: Complete.

```
cat >> ~/week1-cheatsheet.txt << 'EOF'
tail -n 37 ~/week1-cheatsheet.txt
```

Appends the Week 10 section to the master cheat sheet with a heredoc and displays the new entries: ip addr, ip route, ip route add, ss -tlnp, ping -c 4, ssh -v, and the Standard 5 network capture command. The first line opens the heredoc; the entry text itself is in week1-cheatsheet.txt.

Expected output includes: CVNP1601 Week 10 Command Cheat Sheet followed by the seven entries.

Screenshot: 06-week10-cheatsheet-entries

Status: Complete. The Week 3 and Week 4 sections, missing from earlier weeks, were also added between Week 2 and Week 5. A snapshot of the master file is committed in this folder.

## Task 6: Break/Fix Diagnostic

Paper exercise. No commands were run on the VM. See week10-diagnosis.md.

## Evidence Collection

```
cd ~/cvnp1601-portfolio/week10-network-diagnosis
sudo -v
bash collect-evidence.sh
cat evidence-report.txt
```

Refreshes the sudo timestamp, runs the Week 10 evidence script from inside the week folder, and displays the report.

Expected output includes: README.md, week1-cheatsheet.txt, tech-lead-note.md, troubleshooting-narrative.md, and week10-diagnosis.md all FOUND, and the secret scan reporting no obvious secret or token patterns.

Status: Complete.

## Troubleshooting Notes

### Issue 1

Incorrect command: traceroute 8.8.8.8

Root Cause: The traceroute package is not installed on this Ubuntu Server install. The command returned Command 'traceroute' not found.

Resolution: sudo apt install traceroute, as the assignment lists for minimal Ubuntu installs.

Result: traceroute 8.8.8.8 completed in 11 hops with 10.10.50.1 as the first hop.

### Issue 2

Incorrect command: sudo ip route add default via 10.10.50.1

Root Cause: The default route was not missing. The DHCP route via 10.10.50.1 at metric 100 already existed, and the command, given with no metric, added a second default route via the same gateway. A repeat run returned RTNETLINK answers: File exists because that identical route was already in the table.

Resolution: No connectivity fix was needed. The added route was left in place and documented as a runtime only change that clears on reboot.

Result: Both pings and traceroute succeeded with the extra route present, and both default routes appear in the post-fix capture.

### Issue 3

Incorrect command: ssh -v [REDACTED]@10.10.50.103

Root Cause: The command was run on the VM itself instead of from the Windows workstation. The connection to port 22 was established and key exchange completed, but the server accepts publickey authentication only and did not accept the VM's own key.

Resolution: None required for this task. The goal was to confirm sshd is listening and reachable, which the Connection established line shows.

Result: Permission denied with publickey. This is the permission denied failure mode, not connection refused or connection timed out, because sshd answered on port 22.

## Portfolio Card

What I Can Do Now: I can diagnose Linux network connectivity by capturing interface, route, and socket state before and after a change, separating routing from DNS with IP and hostname tests, confirming SSH is listening with ss, and documenting why a runtime ip route add fix does not survive a reboot.

## AI Use Statement

I used Claude to check my written answers for technical errors, draft the Week 3, Week 4, and Week 10 cheat sheet entries, and correct my wording where it was wrong. I ran every command on my own VM and checked each result against the actual output, including the two default routes that ip route add created and the missing traceroute package. Without AI help I can explain why pinging an IP address and a hostname separately splits a routing problem from a DNS problem, and why ip route add does not survive a reboot.

## Files In This Folder

- README.md
- network_20261028_163528.txt
- network_postfix_20261028_172947.txt
- week1-cheatsheet.txt
- tech-lead-note.md
- troubleshooting-narrative.md
- week10-diagnosis.md
- collect-evidence.sh
- evidence-report.txt
- screenshots/01-pre-change-capture.png
- screenshots/02-failure-layer-check.png
- screenshots/03-route-and-connectivity.png
- screenshots/04-ssh-port-22-listening.png
- screenshots/05-post-fix-capture-files.png
- screenshots/06-week10-cheatsheet-entries.png
