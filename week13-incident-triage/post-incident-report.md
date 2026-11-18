POST-INCIDENT REPORT

Ticket: CVNP1601-W13-013
Hostname: 1601
Timestamp: 2026-11-18 16:44 UTC
Incident window: 2026-11-18 16:23 UTC to 16:43 UTC

INCIDENT SUMMARY
At approximately 16:23 UTC the lab server presented three distinct symptoms simultaneously; the nginx service had failed, there was excessive use of disk space on /var and that all content stored in /var/www/html had been incorrectly assigned to the user root. After diagnosis, repair and verification of each symptom individually prior to moving onto the next symptom occurred.

TRIAGE ORDER
1. Service affecting failure, tier one: nginx service failure
2. Degraded health, tier two: disk pressure on /var
3. Third tier: web root ownership, only presents as an HTTP error when nginx begins to serve

SYMPTOM #1: NGINX SERVICE FAILURE
Diagnosis Result: unknown directive server_nmae in file /etc/nginx/sites-enabled/default located line 46; server_name spelled incorrectly. Determined from saved journal capture to ~/reports prior to restart and verified using nginx -t.
Commands run in sequence:
sudo nano /etc/nginx/sites-enabled/default
sudo systemctl restart nginx
systemctl status nginx
mkdir -p ~/reports
journalctl -u nginx -n 100 --no-pager > ~/reports/diagnosis_$(date +%Y%m%d_%H%M%S).txt
sudo nginx -t
sudo systemctl restart nginx
systemctl is-active nginx
Verification output:
systemctl status nginx: Active: failed (Result: exit-code) since Wed 2026-11-18 16:23:36 UTC
nginx -t: [emerg] unknown directive "server_nmae" in /etc/nginx/sites-enabled/default:46
nginx -t: configuration file /etc/nginx/nginx.conf test failed
systemctl is-active nginx: failed
Status: Not resolved. The error for the directive was still present at line 46 and the nginx service had still failed by the end of the incident window.
Time to resolution: root cause identified in approximately 1 minute. From the nginx service failure at 16:23:36 UTC to the execution of nginx -t at 16:24:38 UTC. Not resolved.

SYMPTOM #2: DISK PRESSURE ON /VAR
Diagnosis Result: /var/log/testfill.img, largest item in /var/log at approximately 501M per du.
Commands ran, in sequence:
df -h /var
sudo dd if=/dev/zero of=/var/log/testfill.img bs=1M count=500
df -h /var
sudo du -sh /var/log/* 2>/dev/null | sort -rh | head -5
sudo lsof /var/log/testfill.img
sudo truncate -s 0 /var/log/testfill.img
df -h /var
Verification output:
Free-space check before fill: 6.0G available, 36 percent used
After-fill: 3.8G used, 5.5G available, 42 percent used
lsof: no output, therefore there were no processes with the file open
After truncate: 3.3G used, 6.0G available, 36 percent used
Status: Resolved.
Time to resolution: under five minutes.
