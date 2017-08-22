#!/bin/bash

# your proxy IP
LOCALIP=192.168.178.32
 
# your proxy listening port
DNS_PORT=53

 
# from here
#https://superuser.com/questions/769814/how-to-block-all-ports-except-80-443-with-iptables
#iptables -A INPUT -p tcp -m tcp -m multiport ! --dports 80,443 -j DROP
 
iptables -t nat -A PREROUTING -s $LOCALIP -p tcp --dport $DNS_PORT -j ACCEPT
iptables -t nat -A PREROUTING -p tcp --dport $DNS_PORT -j REDIRECT --to-port $DNS_PORT
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -t mangle -A PREROUTING -p tcp --dport $SQUIDPORT_HTTP -j DROP

