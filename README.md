# Configure-Stingray
Configure-Stingray is a PowerShell script that is meant to be used by other PowerShell scripts to facilitate the configuration automation of a Stingray/SteelApp appliance (all all my docs referred to the software as Stingray, because SteelApp is a horrible name).  It loads the SOAP wsdl of the type of configuration specified and then creates a usable interface in Powershell.  Here is an example workflow that where Configure-Stingray might be used:

![](http://i.imgur.com/7XR20IV.png)

Examples of a configuration type would be a server pool, or a persistence class, or a server SSL certificate.  

Often some aspect of Stingray whose config you wish to automate requires supporting types to be created or configured correctly first.  In cases like this you must run the script for each interface type to complete the config that supports the last type.  For example, you can't create a Virtual Service unless the Traffic IP Group you want to use for that exists first.

![](http://i.imgur.com/K0oEQdS.png)

So in your script to create a Virtual Service you might first create a config interface of type TrafficIPGroup to check for and add as necessary the correct Traffic IP group.  After that is square you can ensure that server Pool is correctly configured, so you might create a config interface of type Pool for that.  Please refer to the Create-VirtualService.ps1 and the MyAppConfig.ps1 files for detailed examples.

Because Configure-Stingray creates the interface using a wsdl written by the makers of Stingray please understand that those methods and properties are created by Riverbed/Brocade, I'm only implementing them for use in Powershell.  For example, as of version 10.0 of Stingray, the provided SOAP interface has no means of configuring a Virtual Server to set an Aptimizer Profile and Scope.  That sucks, but please take your complaints to Brocade.  As soon as the VirtualServer.wsdl supports that functionality my script will too after you update your Stingray software and download its wsdl version for the script to read.
