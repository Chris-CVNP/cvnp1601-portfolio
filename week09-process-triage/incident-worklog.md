Incident Worklog, Ticket CVNP1601-W9-009

Root cause: The server slowdown came from a runaway background bash loop, PID 25577, owned by the lab user account and holding one CPU core at 100 percent. The nginx outage came from a missing semicolon at the end of the worker_connections 768 directive in /etc/nginx/nginx.conf. The journal reported unexpected } in /etc/nginx/nginx.conf:10 and the configuration file test failed, so nginx failed to start at 16:27:00 and again at 16:28:25 UTC.

Fix: The loop was terminated with plain kill, which sends SIGTERM, and it exited on the first attempt, so SIGKILL was not needed. After the journal was captured, the semicolon was restored in nginx.conf, sudo nginx -t reported the syntax is ok and the test is successful, and nginx was restarted with sudo systemctl restart nginx.

Verification: ps aux | grep 25577 returned only the grep command itself, which proved the loop was gone. systemctl is-active --quiet nginx returned nginx is up, which proved the service recovered.

Evidence file: ~/reports/diagnosis_20261022_163046.txt, captured at 16:30:46 UTC, before the successful restart.
