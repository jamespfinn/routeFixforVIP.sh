#!/bin/bash                                                                                                                                                                      
                                                                                                                                                                                 
# 10.12.11 jfinn [routeFixforVIP.sh]                                                                                                                                             
#  Created script to remove route for local subnet via default gatway.                                                                                                           
#  This way the packets that come in via the vip from the local subnet
#  will follow the same path they came in.  All traffic destined for the
#  local subnet that did not pass through the vip will be routed by the
#  default gateway and successfully reach its destination.
#
#  must be run as root.
#
#
#
# Problem: Requests from the same subnet were being responded to directly
#          instead of passing through the VIP.  
#                    |-------|
#     REQUEST--->    |  VIP  |   X----RESPONSE
#         ^          |-------|      |
#         |_________________________|
#
# Solution: Remove route to local subnet to force all trafic to A) follow the 
#           same path in which packets were received  B) follow default gateway
#           for all local subnet traffic
#
# Desired result:
#                    |-------|
#     REQUEST--->    |  VIP  |   <----RESPONSE
#                    |-------|
#
#

INTERFACE="eth0"

IPADDRESS=`/sbin/ifconfig $INTERFACE | grep 'inet addr\:' | awk -F [\:] '{print $2} ' | awk '{print $1}'`
NETMASK=`/sbin/ifconfig $INTERFACE | grep 'inet addr\:' | awk -F [\:] '{print $4} ' | awk '{print $1}'`
NETWORK=`echo $IPADDRESS |  awk -F. '{print $1"."$2"."$3".0"}'`

# check that script was called with our $INTERFACE
# This is used when the script is called as /sbin/ifup-local
# since ifup will call ifup-local with a single argument
# that is the interface e.g. eth0 or lo
# this block prevents errors when bringing up interfaces other 
# than the $INTERFACE
if [ -n "?@" ] ; then
  if [ "$1" != "$INTERFACE" ] ; then
    exit 1
  fi
fi

/sbin/route | /bin/grep "$NETWORK.*$NETMASK.*$INTERFACE" &> /dev/null

if [ $? -eq 0 ] ; then 
    /sbin/route del -net $NETWORK netmask $NETMASK gw 0.0.0.0 $INTERFACE 
    exit 0 
else
  echo "Unable to fix route; Route for network $NETWORK/$NETMASK on $INTERFACE does not exist."
  exit 1
fi

