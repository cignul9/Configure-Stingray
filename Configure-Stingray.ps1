<#
.SYNOPSIS
Automates the provisioning of services through a Stingray/SteelApp load balancer.  Configure-Stingray creates an easy-to-use web-based connector for use in other Powershell scripts to get and set configuration parameters of a specific type for one or more Stingray/SteelApp load balancers.

.DESCRIPTION
Configure-Stingray connects to the specified Stingray, determines its software version and then reads a corresponding wsdl for that software version and the specified configuration type.  The returned object can then be used to write or read that type of configuration settings to and from the Stingray.

Each parameter supports tab completion.  Press tab to indicate the next parameter name or any pre-configured supported values for that parameter.  This is especially handy for the Type parameter, of which there are many.

.PARAMETER Stingray
The name or IP address of a Stingray load balancer.  This is used for secure http connections.  If the domain name for this parameter does not match the provided server certificate Configure-Stingray will not complete a connection successfully, unless you use the IgnoreCertErrors switch parameter.

.PARAMETER Type
Because Stingray configurations are very large the wsdl provided is divided into sections of configuration.  Configure-Stingray returns an object for reading from and writing to the specified type of connection.  The following configuration section names are supported:

	AFM
	AlertCallback
	Alerting.Action
	Alerting.EventType
	Catalog.AptimizerProfile
	Catalog.Authenticators
	Catalog.Bandwidth
	Catalog.DNSServer.ZoneFiles
	Catalog.DNSServer.Zones
	Catalog.JavaExtension
	Catalog.Kerberos.KeyTabs
	Catalog.Kerberos.Krb5Confs
	Catalog.Kerberos.Principals
	Catalog.Monitor
	Catalog.Persistence
	Catalog.Protection
	Catalog.Rate
	Catalog.Rule
	Catalog.SLM
	Catalog.SSL.CertificateAuthorities
	Catalog.SSL.Certificates
	Catalog.SSL.ClientCertificates
	Catalog.SSL.DNSSec
	Custom
	Diagnose
	ExtraFiles
	GLB
	GlobalSettings
	Location
	Pool
	System.AccessLog
	System.Backup
	System.Cache
	System.CloudCredential
	System.Connection
	System.LicenseKey
	System.Log
	System.MachineInfo
	System.Management
	System.NAT
	System.RequestLog
	System.Stats
	System.Steelhead
	TrafficIPGroup
	User
	VirtualServer

How you use the interfaces created by Configure-Stingray is beyond the scope of this help file.  There are hundreds of methods and properties available to configure your Stingray, however there is a basic workflow for figuring out how to use them outlined in the examples.

.PARAMETER WSDLPath
Stingray doesn't seem to publish a wsdl from its SOAP URI, so wsdl files are loaded from a local path.  You must download the wsdl files from a Stingray load balancer and place them on your local machine.  You need only use the WSDLPath parameter if you wish to specify a location for the wsdl files other than the default.

The default path to your wsdl files directory is a directory in the same location as Configure-Stingray and should be named WSDLs.  The WSDLs directory should contain one directory named for each version of Stingray software you need.  You can find the wsdl files you need on any Stingray's $ZEUSHOME/zxtm/etc/wsdl directory.  Just secure copy it off your load balancer.  For example, let's say you have a Stingray running version 9.8r2.  Copy the wsdl files off the Stingray (check out WinSCP for this step) and...(line truncated)...

.PARAMETER Credential
Stingray requires an account to read and/or write its config.  This is passed to Configure-Stingray as a credential object

.PARAMETER CredentialFile
Instead of using a credential object you can store a credential to a file.  Configure-Stingray will import the credential from the file.  The default path and filename of the credential file is the parent path of Configure-Stingray and credential.xml, respectively.  However this may not be a sufficiently secure location for your Stingray credentials, so to create a file with the place and name of your choosing run the following command from a Powershell v4 console:

	Get-Credential <stingray user> | Export-CLIXml <a secure directory the script account can reach>\<any name you like>.xml

Substitute the entries between the brackets (<>) to suit your circumstances.  You will be prompted for the password of the Stingray user you entered.  The username and password will be written to the xml file somewhat securely.  Sure, the password is reversible, but it's better than using plaintext account details in your script.

.PARAMETER IgnoreCertErrors
Often connecting to a management interface Stingray is done without bothering to setup TLS so that the server certificate is trusted by the browser.  IP addresses and short names are used and the server's self-signed certificate is left in place.  When this is the case an error or warning is generated by your browser, which is usually ignored.  However, the default behavior for the web connector objects used by Configure-Stingray is to close the connection.  Setting this switch causes those objects to ignor...(line truncated)...

.EXAMPLE
$MyStingrayVirtualServers = & Configure-Stingray.ps1 -Stingray stingray-node01.mydom.com -Type VirtualServer
# Create a new Stingray configuration object for
# stingray-node01.mydom.com to read/write virtual server configs

C:\PS>$MyStingrayVirtualServers | Get-Member
<big list, redacted>
# Get the list of methods and properties supported by the returned object

C:\PS>$MyStingrayVirtualServers.getVirtualServerNames();
<redacted>
# Get a list of Virtual Server names (useful input parameter for many methods)

C:\PS>$MyStingrayVirtualServers | Get-Member | ?{$_.name -eq 'getBasicInfo'} | select Definition
Definition
----------
VirtualServerBasicInfo[] getBasicInfo(string[] names)
# Get the definition for the getBasicInfo method

C:\PS>$MyStingrayVirtualServers.getBasicInfo('My Tomcat Service')

       port                                       protocol default_pool
       ----                                       -------- ------------
        443                                           http My Tomcat Servers
# Pass a virtual server name string to the getBasicInfo method

.EXAMPLE
$MyStingrayPools = & Configure-Stingray.ps1 -Stingray stingray-node02.mydom.com -Type Pool
# Create a new Stingray configuration object for 
# stingray-node02.mydom.com to read/write server pool configs

C:\PS>$MyStingrayPools | Get-Member
<big list, redacted>
# Get the list of methods and properties supported by the returned object

C:\PS>$MyStingrayPools | Get-Member | ?{$_.Name -eq 'addPool'} | select Definition
Definition
----------
void addPool(string[] names, string[][] nodes)
# Get the definition for the addPool method

C:\PS>$MyStingrayPools.addPool('My App Server Pool', '10.10.10.21:8080')
# Create a new pool called 'My App Server Pool' with one node

C:\PS>$MyStingrayPools | gm | ?{$_.Name -eq 'addNodes'} | select Definition
Definition
----------
void addNodes(string[] names, string[][] values)
# Get the definition for the addNodes method

C:\PS>$MyStingrayPools.addNodes('My App Server Pool', '10.10.10.22:8080')
# Add a second node to the same pool

.NOTES
I borrowed the bit that converts the wsdl to a useable interface from Lee Holmes' Connect-WebService script.  Special thanks to him.

Configure-Stingray requires Powershell version 4 or later.
#>

#requires -version 4
[CmdletBinding(DefaultParametersetName='CredentialFile')] 
param(
	 [Parameter(Mandatory = $True, Position = 0)]
	 [ValidateScript({[System.Net.Dns]::GetHostAddresses("$_")})]
	 [string]$Stingray
	,[Parameter(Mandatory = $True, Position = 1)]
	 [ValidateSet(
		 'AFM'
		,'AlertCallback'
		,'Alerting.Action'
		,'Alerting.EventType'
		,'Catalog.Aptimizer.Profile'
		,'Catalog.Authenticators'
		,'Catalog.Bandwidth'
		,'Catalog.DNSServer.ZoneFiles'
		,'Catalog.DNSServer.Zones'
		,'Catalog.JavaExtension'
		,'Catalog.Kerberos.KeyTabs'
		,'Catalog.Kerberos.Krb5Confs'
		,'Catalog.Kerberos.Principals'
		,'Catalog.Monitor'
		,'Catalog.Persistence'
		,'Catalog.Protection'
		,'Catalog.Rate'
		,'Catalog.Rule'
		,'Catalog.SLM'
		,'Catalog.SSL.CertificateAuthorities'
		,'Catalog.SSL.Certificates'
		,'Catalog.SSL.ClientCertificates'
		,'Catalog.SSL.DNSSec'
		,'Custom'
		,'Diagnose'
		,'ExtraFiles'
		,'GLB'
		,'GlobalSettings'
		,'Location'
		,'Pool'
		,'System.AccessLog'
		,'System.Backup'
		,'System.Cache'
		,'System.CloudCredential'
		,'System.Connection'
		,'System.LicenseKey'
		,'System.Log'
		,'System.MachineInfo'
		,'System.Management'
		,'System.NAT'
		,'System.RequestLog'
		,'System.Stats'
		,'System.Steelhead'
		,'TrafficIPGroups'
		,'User'
		,'VirtualServer'
	 )]
	 [string]$Type
	,[Parameter(Mandatory = $False, Position = 2)]
	 [ValidateScript({Test-Path $_})]
	 [string]$WSDLPath = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)\WSDLs"
	,[Parameter(
		 ParameterSetName = 'CredentialObject'
		,Mandatory = $False
		,Position = 3
	)]
	 [PSCredential]$Credential
	,[Parameter(
		 ParameterSetName = 'CredentialFile'
		,Mandatory = $False
		,Position = 3
	)]
	 [string]$CredentialFile = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)\credential.xml"
	,[switch]$IgnoreCertErrors
)
$Protocol = 'https';
$SoapPort = 9090;
$DebugPreference = 'SilentlyContinue';
$ProgressPreference = 'SilentlyContinue';
function Get-StingrayVersion{
	$Error.Clear();
	$LoginPage = iwr -Uri "$($Protocol)://$($Stingray):$($SoapPort)/apps/zxtm/login.cgi";
	if($Error[0]){
		Show-Error "Unable to determine Stingray software version from the default login URI.";
		return 0;
	}
	$Version = $($LoginPage.AllElements | ?{$_.Class -eq 'version'}).InnerText;
	return $Version;
}
function Ignore-Certificates{
    $Provider = New-Object Microsoft.CSharp.CSharpCodeProvider;
    $Compiler = $Provider.CreateCompiler();
    $Params = New-Object System.CodeDom.Compiler.CompilerParameters;
    $Params.GenerateExecutable = $False;
    $Params.GenerateInMemory = $True;
    $Params.IncludeDebugInformation = $False;
    $Params.ReferencedAssemblies.Add("System.DLL") > $Null;
    $TASource = @'
        namespace Local.ToolkitExtensions.Net.CertificatePolicy{
            public class TrustAll : System.Net.ICertificatePolicy{
                public bool CheckValidationResult(
					 System.Net.ServicePoint sp
					,System.Security.Cryptography.X509Certificates.X509Certificate cert
					,System.Net.WebRequest req
					,int problem){
                    return true;
                }
            }
        }
'@
    $TAResults = $Provider.CompileAssemblyFromSource($Params, $TASource);
    $TAAssembly = $TAResults.CompiledAssembly;
    ## We create an instance of TrustAll and attach it to the ServicePointManager
    $TrustAll = $TAAssembly.CreateInstance("Local.ToolkitExtensions.Net.CertificatePolicy.TrustAll");
    [System.Net.ServicePointManager]::CertificatePolicy = $TrustAll;
}
function Connect-WebService{
	param(
		 [Parameter(Mandatory = $True, Position = 0)]
		 [string] $WSDL
	)
	if(! ${GLOBAL:WebServiceCache}){
		${GLOBAL:WebServiceCache} = @{}
	}
	$OldInstance = ${GLOBAL:WebServiceCache}[$WSDL]
	if($OldInstance){
		return $OldInstance;
	}
	# Load the required Web Services DLL
	[void][Reflection.Assembly]::LoadWithPartialName("System.Web.Services");
	# Download the WSDL for the service, and create a service description from it.
	if (Test-Path $WSDL){
		$ServiceDescription = [Web.Services.Description.ServiceDescription]::Read($WSDL);
	}
	# Because Stingray might one day actually make publish 
	# the wsdl with the API.
	elseif($WSDL -imatch '^http'){
		$WebClient = New-Object System.Net.WebClient;
		$WebClient.UseDefaultCredentials = $True;
		$WSDLStream = $WebClient.OpenRead($WSDL);
		$ServiceDescription = [Web.Services.Description.ServiceDescription]::Read($WSDLStream);
		$WSDLStream.Close();
	}
	if(! $ServiceDescription){
		Show-Error "Unable to fetch wsdl content from $WSDL";
		return;
	}
	# Import the web service into a CodeDom
	$ServiceNamespace = New-Object System.CodeDom.CodeNamespace;
	$CodeCompileUnit = New-Object System.CodeDom.CodeCompileUnit;
	$ServiceDescriptionImporter = New-Object Web.Services.Description.ServiceDescriptionImporter;
	$ServiceDescriptionImporter.AddServiceDescription($ServiceDescription, $null, $null);
	[void]$CodeCompileUnit.Namespaces.Add($ServiceNamespace);
	[void]$ServiceDescriptionImporter.Import($ServiceNamespace, $CodeCompileUnit);
	# Generate the code from that CodeDom into a string
	$GeneratedCode = New-Object Text.StringBuilder;
	$StringWriter = New-Object IO.StringWriter $GeneratedCode;
	$Provider = New-Object Microsoft.CSharp.CSharpCodeProvider;
	$Provider.GenerateCodeFromCompileUnit($CodeCompileUnit, $StringWriter, $null);
	# Compile the source code.
	$References = @('System.dll', 'System.Web.Services.dll', 'System.Xml.dll');
	$CompilerParameters = New-Object System.CodeDom.Compiler.CompilerParameters;
	$CompilerParameters.ReferencedAssemblies.AddRange($References);
	$CompilerParameters.GenerateInMemory = $True;
	$CompilerResults = $Provider.CompileAssemblyFromSource($CompilerParameters, $GeneratedCode);
	# Write any errors if generated.        
	if($CompilerResults.Errors.Count -gt 0){
		$ErrorLines = "";
		foreach($error in $CompilerResults.Errors){
			$ErrorLines += "`n`t" + $error.Line + ":`t" + $error.ErrorText;
		}
		Show-Error $ErrorLines;
		return;
	}
	# There were no errors.  Create the webservice object and return it.
	else{
		# Get the assembly that we just compiled
		$Assembly = $CompilerResults.CompiledAssembly
		# Find the type that had the WebServiceBindingAttribute.
		# There may be other "helper types" in this file, but they will
		# not have this attribute
		$Type = $Assembly.GetTypes() | ?{
			$_.GetCustomAttributes([System.Web.Services.WebServiceBindingAttribute], $False)
		}
		if(! $Type){
			Show-Error "Could not generate web service proxy.";
			return;
		}
		# Create an instance of the type, store it in the cache,
		# and return it to the user.
		$Instance = $Assembly.CreateInstance($Type);
		${GLOBAL:WebServiceCache}[$WSDL] = $Instance;
		return $Instance;
	}
}
function Show-Error{
	param([string]$Message)
	Write-Error $Message;
	Write-Error $Error[0];
	$Error.Clear();
	return;
}
#################### Script execution starts here ####################
# Get the account info we need to connect to the Stingray
# and monkey with its config
if(!$Credential){
	if(!(Test-Path $CredentialFile)){
		$Credential = Get-Credential;
		Write-Verbose "Using credentials for $($Credential.UserName) for authentication to Stingray";	
	}
	else{
		$Error.Clear();
		$Credential = Import-CliXML $CredentialFile;
		if($Error[0]){
			Show-Error "Unable read Stingray credentials from $($CredentialFile)."
			exit;
		}
		Write-Verbose "Using credentials imported from $($CredentialFile) for authentication to Stingray";
	}
}
else{
	Write-Verbose "Using credentials for $($Credential.UserName) for authentication to Stingray";
}
if($IgnoreCertErrors){
	Write-Debug 'Attempting to set certificate policy to Trust All.';
	Ignore-Certificates;
}
# Try to determine which version of Stingray
# we're dealing with.
$StingrayVersion = Get-StingrayVersion;
if(!$StingrayVersion){
	# Update this to the current versions we're running.  
	# Each version of Stingray will need a copy of the 
	# wsdl files
	Write-Verbose "Unable to connect to Stingray at $($Protocol)://$($Stingray):$($SoapPort)/apps/zxtm/login.cgi"
	exit;
}
else{
	Write-Verbose "Connection to $($Stingray) successful!  Using Stingray software version $($StingrayVersion).";
}
$WSDLPath = "$($WSDLPath)\$($StingrayVersion)\$($Type).wsdl";
if(!(Test-Path $WSDLPath)){
	Show-Error "Unable to locate WSDL for type $($Type) at $($Stingray).  Wsdl files must be copied from your Stingray's `$ZEUSHOME/zxtm/etc/wsdl directory.  If you have done this already, then it may be the configuration type $($Type) does not exist for version $($Version) of Stingray.";
	exit;
}
Write-Verbose "Using wsdl found at $($WSDLPath)";
# Generate a cached version of the interface
$Connection = Connect-WebService $WSDLPath;
if(!$Connection){
	Write-Verbose "Unable to create interface for $($Stingray) using $($WSDLPath)."
	exit;
}
# Update this copy of the interface with the correct
# URI and credentials.
$Connection.Url = "$($Protocol)://$($Stingray):$($SoapPort)/soap";
$Connection.Credentials = $Credential;
# Happy configuring
$Connection;