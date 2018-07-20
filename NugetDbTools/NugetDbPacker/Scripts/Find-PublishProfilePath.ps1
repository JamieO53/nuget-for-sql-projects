function Find-PublishProfilePath {
	<#.Synopsis
	Find the project's publish template if any
	.DESCRIPTION
    Finds the .publish.xml file needed to publish the project. This will be "$projectFolder\$projectName.publish.xml" unless
	there is an override of the form "$projectFolder\$projectName.OVERRIDE.publish.xml" which is returned instead. The overrides
	are, in order of priority:
	
	- the specified override
	- The computer host name - not to be used for build servers
	- The host type - DEV, BUILD
	- The git branch

	.EXAMPLE
	Find-PublishProfilePath -ProjectPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.sqlproj
	#>
    [CmdletBinding()]
    param
    (
        # The location of the .sqlproj file being published
		[string]$ProjectPath,
		# The specific override
		[string]$Override = ''
	)

	$suffix = 'publish.xml'
	if (Test-IsRunningBuildAgent) {
		$hostType ='BUILD'
	} else {
		$hostType = 'DEV'
	}

	$path = [IO.Path]::ChangeExtension($ProjectPath, '.publish.xml')
	
	$overrides = @($Override, $Host.Name, $hostType, (Get-Branch))
	$overrides | ? {
		-not [string]::IsNullOrEmpty($_) 
	} | % {
		[IO.Path]::ChangeExtension($ProjectPath, ".$_.publish.xml")
	} | ? {
		Test-Path $_
	} | select -First 1 | % {
		$path = $_
	}
	$path
}