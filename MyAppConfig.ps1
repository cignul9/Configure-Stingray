# Your Stingray management interface
$Stingray = '10.1.1.21';
# Create-VirtualService will rename
# the pool and the TIP according to the
# VS config name if you leave them blank,
# otherwise give them a name.
$VSConfig = @{
	 Name = 'My Web Service'
	;PoolName = ''
	;PoolNodes = @('10.1.17.111:8080', '10.1.17.112:8080')
	;TIPName = ''
	;TIPAddress = '10.1.16.245'
	;BasicInfo = @{
		 port = 443
		;protocol = 'http'
		;default_pool = ''
	 }
	;SSLCertName = 'mydom.com'
	;RequestRules = @(
		 @{
			 name = 'Get Report Service Content'
			;enabled = $True
			;run_frequency = 'run_every'
		 }
		,@{
			 name = 'Get Image Content'
			;enabled = $True
			;run_frequency = 'run_every'
		 }
	 )
	;ResponseRules = @(
		 @{
			 name = 'Strip X-Powered-By and Server Response Headers'
			;enabled = $True
			;run_frequency = 'run_every'
		 }
	 )
	;CompressMIMETypes = @(
		 'application/json'
		,'image/svg+xml'
		,'text/*'
	 )
};
# Uncomment this line to run Create-VirtualService.ps1 and 
# cause Stingray to build this virtual service
#& c:\program files\scripts\Stingray\Create-VirtualService.ps1 -Stingray $Stingray -Config $VSConfig -UseGUID;