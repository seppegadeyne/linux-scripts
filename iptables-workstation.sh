#!/bin/bash

## Reset iptables
iptables -F
iptables -X
iptables -Z

## Set default policy
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

## Allow everything on localhost
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

## Make sure NEW incoming tcp connections are SYN packets, otherwise drop them
iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP

## Drop packets with incoming fragments
iptables -A INPUT -f -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

## Drop incoming malformed XMAS packets
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP

## Drop all NULL packets
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

## Drop FIN packet scans
iptables -A INPUT -p tcp --tcp-flags FIN,ACK FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

## Get rid of broadcast / multicast and invalid
iptables -A INPUT -m pkttype --pkt-type broadcast -j DROP
iptables -A INPUT -m pkttype --pkt-type multicast -j DROP
iptables -A INPUT -m state --state INVALID -j DROP

# Allow outgoing TCP connections to port 22,22022,53,80,443,587,1883
iptables -A OUTPUT -p tcp -m multiport --dports 22,8443,53,80,443,587,1883 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -m multiport --sports 22,8443,53,80,443,587,1883 -m state --state ESTABLISHED -j ACCEPT

# Allow outgoing UDP connections to port 53,67,123,443
iptables -A OUTPUT -p udp -m multiport --dports 53,123,443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p udp -m multiport --sports 53,123,443 -m state --state ESTABLISHED -j ACCEPT

# Allow outgoing ICMP connections
iptables -A OUTPUT -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p icmp --icmp-type 0 -m state --state ESTABLISHED,RELATED -j ACCEPT

## Log all other connections and drop them afterwards
iptables -A INPUT -j LOG --log-prefix "IPTABLES INPUT: "
iptables -A OUTPUT -j LOG --log-prefix "IPTABLES OUTPUT: "
iptables -A INPUT -j DROP
iptables -A OUTPUT -j DROP

## End setup iptables
iptables -L -n -v
