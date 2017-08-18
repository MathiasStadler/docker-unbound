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

iptables -t nat -I OUTPUT -m owner ! --uid-owner $UNBOUND_UID ! -d $DEST_IP -p udp --dport $DNS_PORT -j DNAT --to 127.0.0.1:53
iptables -t nat -I OUTPUT -m owner ! --uid-owner $UNBOUND_UID ! -d $DEST_IP -p tcp --dport $DNS_PORT -j DNAT --to 127.0.0.1:53

