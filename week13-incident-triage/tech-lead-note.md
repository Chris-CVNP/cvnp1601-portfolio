The issue was that there were three issues in this order. First was the nginx service. Second was disk pressure on /var. Third was improper ownership of /var/www/html. Each individual problem was addressed and verified separately.
Tier one, first, failure:
nginx service failed
nginx service failed due to an unknown directive called server_nmae at line 46 of /etc/nginx/sites-enabled/default. The command journalctl -u nginx -n 100 --no-pager > ~/reports/diagnosis_$(date +%Y%m%d_%H%M%S).txt saved a copy of the last 100 nginx journal entries prior to the second restart or attempting to correct the issue. The command nginx -t indicated that the syntax error remained and the directive was not corrected. Therefore, nginx failed again at the end of the incident, and systemctl is-active nginx returned failed.
Tier two, second:
Disk pressure issue
The disk pressure was caused by a 500 MB file named /var/log/testfill.img. sudo lsof /var/log/testfill.img did not show any processes had this file open. truncate -s 0 /var/log/testfill.img emptied the file, and df -h /var reported that /var dropped from 42% back to 36% being used.
Tier three, third:
Web root ownership issue
The owner of /var/www/html was listed as root:root. The command sudo chown -R www-data:www-data /var/www/html corrected the ownership, and ls -la /var/www/html confirmed the correction. However, curl -I http://localhost could not confirm that the server responded to http requests because nginx was unavailable.
