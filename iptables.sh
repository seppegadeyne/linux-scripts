#!/bin/bash

## Set variables for iptables configuration
IP_SERVER="161.97.160.205"
# Your DNS servers you use: cat /etc/resolv.conf
DNS_SERVER="127.0.0.53 161.97.189.51 161.97.189.52"

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

## Disable incoming ping requests
iptables -A INPUT -p icmp -s 0/0 -d $IP_SERVER -m state --state NEW,ESTABLISHED,RELATED -j REJECT
iptables -A OUTPUT -p icmp -s $IP_SERVER -d 0/0 -m state --state ESTABLISHED,RELATED -j REJECT

## Enable outgoing ping requests
iptables -A OUTPUT -p icmp -s $IP_SERVER -d 0/0 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p icmp -s 0/0 -d $IP_SERVER -m state --state ESTABLISHED,RELATED -j ACCEPT


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
iptables -A INPUT -m state --state ESTABLISHED,RELATED -m limit --limit 1000/s --limit-burst 1250 -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j DROP
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

## Allow SSH
iptables -A INPUT -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

## Allow DNS lookups
for ip in $DNS_SERVER 
do
	iptables -A OUTPUT -p udp -d $ip --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT -p udp -s $ip --sport 53 -m state --state ESTABLISHED -j ACCEPT
	iptables -A OUTPUT -p tcp -d $ip --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	iptables -A INPUT -p tcp -s $ip --sport 53 -m state --state ESTABLISHED -j ACCEPT
done

## Redirect one port to another, idea for Node.js app server
# iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8080 -j REDIRECT --to-port 80

# Allowing new and established incoming connections to port 80, 443
iptables -A INPUT -p tcp -m multiport --dports 80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -m multiport --sports 80,443 -m state --state ESTABLISHED -j ACCEPT

# Allowing new and established outgoing connections to port 80, 443
iptables -A OUTPUT -p tcp -m multiport --dports 80,443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -m multiport --sports 80,443 -m state --state ESTABLISHED -j ACCEPT

# Allow outgoing connections to port 123 (ntp syncs)
iptables -A OUTPUT -p udp --dport 123 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p udp --sport 123 -m state --state ESTABLISHED -j ACCEPT

## Log all other connections and drop them afterwards
iptables -A INPUT -j LOG --log-prefix "IPTABLES INPUT: "
iptables -A OUTPUT -j LOG --log-prefix "IPTABLES OUTPUT: "
iptables -A INPUT -j DROP
iptables -A OUTPUT -j DROP

## End setup iptables
iptables -L -n -v

