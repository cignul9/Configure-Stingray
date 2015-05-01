param(
	 [Parameter(Mandatory = $True; Position = 0)]
	 [string]$Stingray
	,[Parameter(Mandatory = $True; Position = 1)]
	 [hashtable]$Config
	,[Parameter(Mandatory = $True; Position = 2)]
	 [switch]$UseGUID
	,[Parameter(Mandatory = $False)]
	 [string]$StingrayConnectScript = 'c:\program files\scripts\configure-stingray\configure-stingray.ps1'
	,[Parameter(Mandatory = $False)]
	 [string]$WSDLPath = 'c:\program files\scripts\stingray\wsdls'
	,[Parameter(Mandatory = $False)]
	 [string]$CredentialFile = 'c:\program files\scripts\stingray\credential.xml'
)
$ErrorActionPreference = 'SilentlyContinue';
trap{
	Write-Verbose "Error at step: $($Step)`n$($Error[0])";
}
if($UseGUID){
	$SmallGUID = $([guid]::NewGuid()).guid.substring(24);
	$Config.Name = "$($Config.Name) $($SmallGUID)";
	$Config.VSName = "$($Config.Name) Service";
}
if(!$Config.TIPName -or $Config.TIPName -eq ''){
	$Config.TIPNameName = "$($Name) TIP";
}
if(!$Config.PoolName -or $Config.PoolName -eq ''){
	$Config.PoolName = "$($Name) Servers";
}
# Create a persistence class
$Step = 'Creating a Persistence Class';
$Persistence = & $StingrayConnectScript `
	-Stingray $Stingray `
	-Type Catalog.Persistence `
	-WSDLPath $WSDLPath `
	-CredentialFile $CredentialFile `
	-IgnoreCertErrors;
$Persistence.addPersistence("$($Name) Session Persistence");
$Persistence.setType($Config.Name,'j2ee');
#Create a server pool
$Step = 'Creating a Server Pool';
$Pool = & $StingrayConnectScript `
	-Stingray $Stingray `
	-Type Pool `
	-WSDLPath $WSDLPath `
	-CredentialFile $CredentialFile `
	-IgnoreCertErrors;
# I haven't figured out how to successfully delimit 
# nodes for multiple node entries.  Help!
$Pool.addPool($Config.PoolName, $Config.PoolNodes[0]);
# For this reason I added one node with the addPool method 
# and the others with the addNodes method, one at a time.
for($i = 1, $i -le $Config.PoolNodes.count, $i++){
	$Pool.addNodes($Config.PoolName, $Config.PoolNodes[$i]);
}
# Create a traffic IP group
$Step = 'Creating a Traffic IP Group';
$TIP = & $StingrayConnectScript `
	-Stingray $Stingray `
	-Type TrafficIPGroups `
	-WSDLPath $WSDLPath `
	-CredentialFile $CredentialFile `
	-IgnoreCertErrors;
$TIP.addTrafficIPGroup($Config.TIPName, $Config.TIPAddress);
# Create a Virtual Server
$Step = 'Creating a Virtual Server';
$VS = & $StingrayConnectScript `
	-Stingray $Stingray `
	-Type VirtualServer `
	-WSDLPath $WSDLPath `
	-CredentialFile $CredentialFile `
	-IgnoreCertErrors;
$VS.addVirtualServer($Config.VSName, $Config.BasicInfo);
$VS.setListenTrafficIPGroups($Config.VSName, $Config.TIPName);
$VS.setSSLDecrypt($Config.VSName, $True);
$VS.setSSLCertificate($Config.VSName, $Config.SSLCertName);
$VS.setSSLSupportSSL2($Config.VSName, 'disabled');
$VS.setSSLSupportSSL3($Config.VSName, 'disabled');
# For Aptimizer this is all the API can do right now :(
# I may create a separate Aptimizer config tool to
# complete the process of at least associating a 
# preconfigured profile and scope to your Virtual Service
$VS.setAptimizerEnabled($Config.VSName, $True);
$VS.setKeepalive($Config.VSName, $True);
$VS.setCompressionEnabled($VConfig.SName, $True);
$VS.setCompressionLevel($Config.VSName, 5);
for($i = 0; $i -lt $Config.CompressMIMETypes.count; $i++){
	$VS.addCompressionMIMETypes($Config.VSName, $Config.CompressMIMETypes[$i]);
}
for($i = 0; $i -lt $Config.RequestRules.count; $i++){
	$VS.addRules($Config.VSName, $Config.RequestRules[$i]);
}
for($i = 0; $i -lt $Config.ResponseRules.count; $i++){
	$VS.addResponseRules($Config.VSName, $Config.ResponseRules[$i]);
}
$VS.setUseNagle($Config.VSName, $False);
$VS.setEnable($Config.VSName, $True);
#If we create the VS with a GUID, return that so it
# can be used to further tweak the service or
# eventually remove it.
$SmallGUID;