#!/bin/sh

ssh-keygen -A

mkdir -p /var/git/.ssh
touch /var/git/.ssh/authorized_keys
chmod 644 /var/git/.ssh/authorized_keys

chmod 766 /var/run/docker.sock

/usr/sbin/sshd -D
