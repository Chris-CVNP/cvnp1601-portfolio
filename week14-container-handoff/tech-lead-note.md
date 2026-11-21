The helpdesk-web container is being run off of the pinned image nginx:1.25-alpine as opposed to a floating latest tag which means it's possible to identify what image will be used every time the image is pulled/the container is recreated.
Docker is publishing container port 80 on the host port 8080 for both IPv4 and IPv6 and the restart policy is set to unless-stopped.
The named volume helpdesk-data is mounted at /usr/share/nginx/html therefore all web content exists outside of the disposable container layer and will survive when the container is recreated.
Verification successfully completed at three different levels:
docker ps indicated the container is up and the correct port mapping was applied
curl -I http://localhost:8080 returned an HTTP/1.1 200 OK from nginx version 1.25.5
docker logs recorded the test request and reported a 200 status.
After restarting the container and stopping then starting again the previous verification process ran without errors.
Rollback will simply remove the current instance of the container and recreate the same container using the same tag, port, volume and restart policy found in docker-run.txt.
Remaining Risks/Risks Not Identified During Testing:
the service has only been tested from within the host
restarts keep the container alive however do not verify if the application is healthy
running docker volume rm helpdesk-data will delete all data stored in the volume.
