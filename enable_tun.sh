#!/bin/sh

chmod +s $(which aratapif)

modprobe tun
chown $1 /dev/net/tun
sleep 1
tunctl -t tap0 -u $1
sleep 1
ifconfig tap0 192.168.251.1 pointopoint 192.168.251.2 netmask 255.255.255.255 up
iptables -t nat -A POSTROUTING -s 192.168.251.2 -j MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward
