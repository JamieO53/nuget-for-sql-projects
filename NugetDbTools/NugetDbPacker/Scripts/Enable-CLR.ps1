function Enable-CLR{
	<#.Synopsis
	Enable CLR on the specified server
	.DESCRIPTION
    Finds the .publish.xml file needed to publish the project. This will be "$projectFolder\$projectName.publish.xml" unless
	there is an override of the form "$projectFolder\$projectName.OVERRIDE.publish.xml" which is returned instead. The overrides
	are, in order of priority:
	
	- the specified override
	- The computer host name - not to be used for build servers
	- The host type - DEV, BUILD
	- The repository branch

	.EXAMPLE
	Enable-CLR -ProfilePath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.profile.xml
	#>
    [CmdletBinding()]
    param
    (
        # The location of the .profile.xml file being published
		[string]$ProfilePath
	)
	
	if(-not (Get-InstalledModule SqlServer)) {
		Install-Module SqlServer
	}
	Import-Module SqlServer -Global -DisableNameChecking
	[xml]$doc = gc $ProfilePath
	[string]$connectionString = $doc.Project.PropertyGroup.TargetConnectionString
	$query = @'
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'clr enabled', 1;
GO
RECONFIGURE;
GO
sp_configure 'show advanced options', 0;
GO
RECONFIGURE;
GO
'@
	Invoke-Sqlcmd -ConnectionString $connectionString -Query $query
}
