FROM alpine:3.7

RUN apk update && \
    apk add --no-cache bash==4.4.19-r1 \
    vsftpd==3.0.3-r4 unbound==1.6.7-r1 \
    nginx==1.12.2-r3

# Configure openrc
RUN mkdir /run/openrc && \
    touch /run/openrc/softlevel

# Set up Nginx
RUN adduser -D -g 'www' www && \
    mkdir -p /www/files && \
    mkdir -p /run/nginx && \
    chown -R www:www /var/lib/nginx && \
    chown -R www:www /www

COPY ./config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./config/nginx/index.html /www/index.html

# Set up vsftpd
COPY ./config/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf

COPY ./config/run.sh /run.sh

EXPOSE 20 21 80 10090-10100

ENTRYPOINT /bin/bash /run.sh