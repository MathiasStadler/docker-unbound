#!/bin/bash

#from here
#http://www.bsdforen.de/threads/brauch-mal-ne-%C3%9Cbersetzung-iptables-zu-ipfw.32613/
#Dank an den Rosendoctor

#iptables -t nat -I OUTPUT -m owner ! --uid-owner <uid von unbound> ! -d 88.xxx.yyy.146 -p udp --dport 53 -j DNAT --to 127.0.0.1:53
#iptables -t nat -I OUTPUT -m owner ! --uid-owner <uid von unbound> ! -d 88.xxx.yyy.146 -p tcp --dport 53 -j DNAT --to 127.0.0.1:53


DNS_PORT=53
UNBOUND_UID=1000
INTERNET_DEVICE=eno1
DEST_IP=192.168.178.32

#sudo iptables -t nat -I OUTPUT -m owner ! --uid-owner $UNBOUND_UID ! -d $DEST_IP -p udp --dport $DNS_PORT -j DNAT --to 127.0.0.1:53
#sudo iptables -t nat -I OUTPUT -m owner ! --uid-owner $UNBOUND_UID ! -d $DEST_IP -p tcp --dport $DNS_PORT -j DNAT --to 127.0.0.1:53


iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to DEST_IP:5353
iptables -t nat -A OUTPUT -p tcp --dport 53 -j DNAT --to DEST_IP:5353

#from here
# https://unix.stackexchange.com/questions/144482/iptables-to-redirect-dns-lookup-ip-and-port
iptables -t nat -A PREROUTING -p tcp --sport 53 -j DNAT --to-destination 23.226.230.72:5353
iptables -t nat -A POSTROUTING -j MASQUERADE