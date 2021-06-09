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
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

## Excercise KdG
iptables -A INPUT -p icmp -m limit -j LOG --log-prefix "IPTABLES ICMP: "

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

## Reject connections above 30 from one source IP
iptables -A INPUT -p tcp --syn --dport 80 -m connlimit --connlimit-above 100 --connlimit-mask 31 -j REJECT --reject-with tcp-reset
iptables -A INPUT -p tcp --syn --dport 443 -m connlimit --connlimit-above 100 --connlimit-mask 31 -j REJECT --reject-with tcp-reset

## Allow 1000 new connections (packets) per second
iptables -A INPUT -m state --state ESTABLISHED,RELATED -m limit --limit 1000/second --limit-burst 1250 -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j DROP

## Allow http and https
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80 -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -m state --state ESTABLISHED -j ACCEPT

## Allow dns lookup
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

## Log all other connections
iptables -A INPUT -j LOG --log-prefix "IPTABLES INPUT: "
iptables -A OUTPUT -j LOG --log-prefix "IPTABLES OUTPUT: "

## Drop all other connections
iptables -A INPUT -j DROP

## End setup iptables
iptables -L -n -v

