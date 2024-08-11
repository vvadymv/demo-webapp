FROM busybox
CMD while true ; do { echo -e 'HTTP/1.1 200 OK\n\n Version 1.0.0'; } | nc -vlp 8080; done
COPY what_am_I_doing_here /
EXPOSE 8080