#!/bin/bash

## Reset iptables
iptables -F
iptables -X
iptables -Z

## Set default policy
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

## Allow SSH
iptables -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

## Make sure NEW incoming tcp connections are SYN packets, otherwise drop them
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP

## Drop packets with incoming fragments
iptables -A INPUT -f -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

## Drop incoming malformed XMAS packets
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-prefix "IPTABLES XMAS packets: "
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP

## Drop all NULL packets
iptables -A INPUT -p tcp --tcp-flags ALL NONE -m limit --limit 5/m --limit-burst 7 -j LOG --log-prefix "IPTABLES NULL packets: "
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

## Drop FIN packet scans
iptables -A INPUT -p tcp --tcp-flags FIN,ACK FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-prefix "IPTABLES FIN packets scan: "
iptables -A INPUT -p tcp --tcp-flags FIN,ACK FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

## Log and get rid of broadcast / multicast and invalid
iptables -A INPUT -m pkttype --pkt-type broadcast -j LOG --log-prefix "IPTABLES broadcast: "
iptables -A INPUT -m pkttype --pkt-type broadcast -j DROP
iptables -A INPUT -m pkttype --pkt-type multicast -j LOG --log-prefix "IPTABLES multicast: "
iptables -A INPUT -m pkttype --pkt-type multicast -j DROP
iptables -A INPUT -m state --state INVALID -j LOG --log-prefix "IPTABLES invalid: "
iptables -A INPUT -m state --state INVALID -j DROP

## Reject connections above 30 from one source IP
iptables -A INPUT -p tcp --syn --dport 80 -m connlimit --connlimit-above 100 --connlimit-mask 31 -j REJECT --reject-with tcp-reset
iptables -A INPUT -p tcp --syn --dport 443 -m connlimit --connlimit-above 100 --connlimit-mask 31 -j REJECT --reject-with tcp-reset

## Allow 300 new connections (packets) per second
iptables -A INPUT -m state --state ESTABLISHED,RELATED -m limit --limit 300/second --limit-burst 320 -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

## Allow webserver
iptables -A INPUT -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT

## Log all other and then drop them
iptables -A INPUT -p tcp -j LOG --log-prefix "IPTABLES TCP-INPUT: "
iptables -A INPUT -p udp -j LOG --log-prefix "IPTABLES UDP-INPUT: "
iptables -A OUTPUT -p tcp -j LOG --log-prefix "IPTABLES TCP-OUTPUT: "
iptables -A OUTPUT -p udp -j LOG --log-prefix "IPTABLES UDP-OUTPUT: "

## Drop all other connections
iptables -A INPUT -j DROP

## End setup iptables
iptables -L -n -v
