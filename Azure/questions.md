how to calculate the no of subnet with /y we can have in a VNet with /x  


app service and app service plan
multiple app services can make use of same service plan - 

Yes, explicitly. Behind every App Service Plan, there are actual virtual machines (VMs) running in Microsoft's datacenters. When you configure an App Service Plan, you are provisioning:Dedicated CPU cores and RAM: The size and power of the underlying VMs depend entirely on the pricing tier you choose (e.g., Basic, Premium, Isolated). Instance Count: If you scale out your App Service Plan to 3 instances, Azure provisions 3 identical underlying VMs to handle your traffic.

App Service Plan = A Hotel Room. You pay a flat rate for the room, which comes with a set amount of space (CPU/RAM) and beds (Instances).
App Services = The Guests. You can put one guest in the room, or you can put four guests in the room. The price stays the same, but the guests have to share the available space. If one guest starts taking up all the room, the others will feel crowded ("noisy neighbour" effect).


VM - stopped v/s dealocated 
VM - auto shoutdown (deallocating the CPU and RAM) to save cost

azure me vnet , peering , hub spoke 
load balancer 
firewall 
if we have nsg so why we need firewall 
nat rules 
nat 
osi model complete explain 
 