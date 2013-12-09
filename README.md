routeFixforVip.sh
=================
 10.12.11 jfinn [README]                                                                                                                                             
  Created script to remove route for local subnet via default gatway.                                                                                                           
  This way the packets that come in via the vip from the local subnet
  will follow the same path they came in.  All traffic destined for the
  local subnet that did not pass through the vip will be routed by the
  default gateway and successfully reach its destination.

  must be run as root.



 Problem: Requests from the same subnet were being responded to directly
//          instead of passing through the VIP.  
//                 |-------|
//   REQUEST--->    |  VIP  |   X----RESPONSE
//       ^          |-------|      |
//      |_________________________|

 Solution: Remove route to local subnet to force all trafic to A) follow the 
 same path in which packets were received  B) follow default gateway
 for all local subnet traffic

 Desired result:
//                 |-------|
//  REQUEST--->    |  VIP  |   <----RESPONSE
//                 |-------|


