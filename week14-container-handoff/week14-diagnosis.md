State

docker run provided a detached reportgen-web container from the pinned registry.local/reportgen:2.3 image. It did this using the unless-stopped restart policy, and provided the host port 8080 as mapped to the container port 80. Upon completion of docker run, Docker issued a container ID to confirm creation of a new container object and successful start of the container.

docker ps --filter name=reportgen-web confirmed that the container had been up for 14 minutes and reported as running using the expected image. As well, docker ps identified that the PORTS 0.0.0.0:8080->80/tcp were properly published at the Docker level. However, this only indicates that a process is running within the container and that the port is published at the Docker level. It does NOT indicate whether the process is actually responding.

As a result, curl -I http://localhost:8080 resulted in Connection refused after 2ms. Since there was no delay involved, it indicated that the connection reached some entity that actively rejected it due to there being no one waiting to accept it on the other side of the connection. Typically, if a firewall dropped incoming traffic it results in a time out rather than an instantaneous rejection.

docker logs --tail 20 reportgen-web confirmed that the server had successfully started, and then immediately reported Server listening on 127.0.0.1:80. The port number was correct; however, the IP address was the loopback address within the container.

docker inspect reportgen-web --format '{{json .HostConfig.PortBindings}}' showed 80/tcp bound to HostPort 8080 with an empty HostIp, indicating all host IP addresses. Both docker ps and docker inspect indicate proper configuration for the port mapping.

Root Cause

The application is binding to 127.0.0.1 within the container instead of all interfaces. Each container has its own network namespace with its own loopback interface. Therefore, when using Docker's port mapping to forward traffic into the container via a host IP address/ports combination, it is forwarded to the container's bridge network interface and not to the container's loopback interface. Therefore, a process that only accepts 127.0.0.1 will never receive these packets and hence returns connection refused. docker ps and docker inspect both appeared to have valid configurations since they are describing only the container object and the port mappings and do not provide information about what address the application selected for listening purposes. The theory regarding firewalls and Docker networking does not align with evidence as the mapping is correct, the failure occurred instantly, and the log message explicitly identifies the bind address.

Remediation

Step One: Change the application's listen address from 127.0.0.1 to 0.0.0.0 without modifying either the port mapping or host firewall. First, I would document current state by capturing additional evidence utilizing docker logs reportgen-web. Then I would utilize docker inspect reportgen-web --format '{{json .Config.Env}}' and docker inspect reportgen-web --format '{{json .Config.Cmd}}' to determine where the image configuration sets its bind address and verify according to reportgen image documentation for appropriate settings of supported options. A listen address cannot be modified on a running container, therefore I would next delete it using docker rm -f reportgen-web and create another identical container with same name/image-tag/port-mapping/restart-policy as previous instance of reportgen-web while including documented environment variable or command parameter setting the listen-address to 0.0.0.0.

Verification

Firstly, verification of resolution can be performed at the Application Boundary level by utilizing docker logs --tail 20 reportgen-web to obtain an updated log message showing Server listening on 0.0.0.0:80 instead of Server listening on 127.0.0.1:80, thus proving that application processes are accepting inbound requests on all applicable container local interfaces.

Secondly, verification of resolution can be completed at User Boundary level by testing connectivity from outside container boundaries by utilizing curl -I http://localhost:8080 on host14 to confirm receipt of an HTTP Status Line instead of receiving Connection refused error messages, and utilize curl -I http://host14:8080 on another system connected to same network segment as host14's assigned IP address on port 8080 to confirm receipt of an HTTP Response message. Thus confirming that traffic is traversing Docker port mapping layers and reaching applications from hosts and networks external to the container shell session, not solely based upon a test executed from a shell within container session. docker ps and docker inspect should continue to display identical Up status and 8080 -> 80 mapping indications; however, these indications are supplementary since they similarly displayed correct indication prior to performing remediation steps.
