#!/bin/bash

#from here
#http://www.bsdforen.de/threads/brauch-mal-ne-%C3%9Cbersetzung-iptables-zu-ipfw.32613/
#Dank an den Rosendoctor

#iptables -t nat -I OUTPUT -m owner ! --uid-owner <uid von unbound> ! -d 88.xxx.yyy.146 -p udp --dport 53 -j DNAT --to 127.0.0.1:53
#iptables -t nat -I OUTPUT -m owner ! --uid-owner <uid von unbound> ! -d 88.xxx.yyy.146 -p tcp --dport 53 -j DNAT --to 127.0.0.1:53


DNS_PORT=53
DNS_PROXY_PORT=15353
UNBOUND_UID=1000
INTERNET_DEVICE=eno1
DEST_IP=192.168.178.32

UNBOUND_PID=$(ps -ef|grep /opt/unbound/sbin/unbound |grep -v grep |awk '{print $2}');

echo $UNBOUND_PID;


#sudo iptables -t nat -I OUTPUT -m owner ! --uid-owner $UNBOUND_UID ! -d $DEST_IP -p udp --dport $DNS_PORT -j DNAT --to 127.0.0.1:53
#sudo iptables -t nat -I OUTPUT -m owner ! --uid-owner $UNBOUND_UID ! -d $DEST_IP -p tcp --dport $DNS_PORT -j DNAT --to 127.0.0.1:53


#iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to DEST_IP:5353
#iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to DEST_IP:5353

#from here
# https://unix.stackexchange.com/questions/144482/iptables-to-redirect-dns-lookup-ip-and-port
#iptables -t nat -A OUTPUT -p tcp --dport $DNS_PORT -j DNAT --to $DEST_IP:$DNS_PROXY_PORT;
#iptables -t nat -A OUTPUT -p udp --dport $DNS_PORT -j DNAT --to $DEST_IP:$DNS_PROXY_PORT;
#iptables -t nat -A POSTROUTING -j MASQUERADE


iptables -t nat -A OUTPUT -m owner ! --pid-owner $UNBOUND_PID -p tcp --dport $DNS_PORT -j DNAT --to $DEST_IP:$DNS_PROXY_PORT;
iptables -t nat -A OUTPUT -m owner ! --pid-owner $UNBOUND_PID -p udp --dport $DNS_PORT -j DNAT --to $DEST_IP:$DNS_PROXY_PORT;
iptables -t nat -A POSTROUTING -j MASQUERADE