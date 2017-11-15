#!/bin/bash


# from here
# https://www.cyberciti.biz/tips/linux-iptables-how-to-flush-all-rules.html

echo "Stopping firewall and allowing everyone..."
ipt="/sbin/iptables"
## Failsafe - die if /sbin/iptables not found
[ ! -x "$ipt" ] && { echo "$0: \"${ipt}\" command not found."; exit 1; }
$ipt -P INPUT ACCEPT
$ipt -P FORWARD ACCEPT
$ipt -P OUTPUT ACCEPT
$ipt -F
$ipt -X
$ipt -t nat -F
$ipt -t nat -X
$ipt -t mangle -F
$ipt -t mangle -X
$ipt -t raw -F
$ipt -t raw -X

$ipt -L -n -v

#old version
#iptables -F
#iptables -X
#iptables -t nat -F
#iptables -t nat -X
#iptables -t mangle -F
#iptables -t mangle -X