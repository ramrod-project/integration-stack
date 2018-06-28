#!/bin/bash

# start nginx
nginx -g 'daemon off;' &

# start vsftpd
/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf