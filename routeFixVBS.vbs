' 12.06.13 jfinn
'   Created VB Script to correct the routing issue for servers behind the F5 LTM
'   on Windows.  The script will determine the list of interfaces (if more than one)
'   It will then iterate over them to determine any routes that exist to the local 
'   subnet(s).  The script will create a new static route to the local subnet with 
'   a gateway of the determined default gatewway and a metric value of 1.  The pre-
'   existing static route to the local subnet has a metric of 10, by creating a new
'   route with a higher priority metric, we will force traffic to be routed through
'   the VIP rather than direct-repsonse via the local subnet. 
'
'   This script should be run at boot after the network interfaces have been brought
'   online.
'
'   While it would be possible to add this new route as a persistent route, we would
'   not be able to easily accomodate the possibility of a change in IP or subnet.
'
'On Error Resume Next

dim NIC1, Nic, StrIP, CompName, DefaultRoute

    Const cComputerName = "LocalHost"
    Const cWMINameSpace = "root/cimv2"
    Const cWMIIP4RouteClass = "Win32_IP4RouteTable"
    Const cWMIIPPersistedRouteClass = "Win32_IP4PersistedRouteTable"
    Const cWMIActiveRouteClass = "Win32_ActiveRoute"

Set NIC1 = GetObject("winmgmts:").InstancesOf("Win32_NetworkAdapterConfiguration")

For Each Nic in NIC1

if Nic.IPEnabled then
  StrIP = Nic.IPAddress(i)
  Set WshNetwork = WScript.CreateObject("WScript.Network")
  CompName= WshNetwork.Computername
  Wscript.Echo "IP Address: "&StrIP & vbNewLine _
    & "Computer Name: "&CompName

  strComputer = "."
  Set objWMIService = GetObject("winmgmts:" _
      & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

  Set defRoute = objWMIService.ExecQuery("Select * from Win32_IP4RouteTable WHERE Destination = '0.0.0.0'")
  For Each rte in defRoute
                DefaultRoute = rte.NextHop
                Wscript.Echo "Default route hop: " &DefaultRoute
  Next
  Set colItems = objWMIService.ExecQuery("Select * from Win32_IP4RouteTable WHERE NextHop = '" & StrIP &"' AND NOT Destination LIKE '%.%.255.255' AND Destination != '224.0.0.0'")
 
  For Each objItem in colItems
      Wscript.Echo "Age: " & objItem.Age
      Wscript.Echo "Description: " & objItem.Description
      Wscript.Echo "Destination: " & objItem.Destination
      Wscript.Echo "Information: " & objItem.Information
      Wscript.Echo "Interface Index: " & objItem.InterfaceIndex
      Wscript.Echo "Mask: " & objItem.Mask
      Wscript.Echo "Metric 1: " & objItem.Metric1
      Wscript.Echo "Metric 2: " & objItem.Metric2
      Wscript.Echo "Metric 3: " & objItem.Metric3
      Wscript.Echo "Metric 4: " & objItem.Metric4
      Wscript.Echo "Metric 5: " & objItem.Metric5
      Wscript.Echo "Name: " & objItem.Name
      Wscript.Echo "Next Hop: " & objItem.NextHop
      Wscript.Echo "Protocol: " & objItem.Protocol
      Wscript.Echo "Type: " & objItem.Type
      Wscript.Echo ""
          Wscript.Echo ""
          Wscript.Echo ""
          
          ' Now we are going to add a route to objItem.Destination (the local subnet) 
          ' the route is going to have a mask of objItem.Mask (the local subnets's netmask)
          ' the route is going to have a gateway of the DefaultRoute
          ' We wil also assign it a metric of 1 to ensure its the highest priority, this will
          ' ensure that the local subnet traffic will be routed through the F5 instead of directly
          ' since we have a lower (>priority) metric than the default subnet route (has a metric 10)
          ' this new route will take priority and let us operate properly without the need for removing 
          ' the other route.
          
          Set objShell = Wscript.CreateObject("WScript.Shell")
          command = "cmd /K route add " & objItem.Destination & " mask " & objItem.Mask & " " & DefaultRoute & " metric 1"
	        Wscript.Echo "Executing: " &command
	        objShell.Run (command)
	  
  Next
end if
Next
