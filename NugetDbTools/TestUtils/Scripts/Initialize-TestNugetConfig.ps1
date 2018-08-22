function Initialize-TestNugetConfig {
	param (
		[switch]$NoOptions = $false,
		[switch]$NoSettings = $false,
		[switch]$NoDependencies = $false,
		[string]$Content = ''
	)
	$nugetOptions = New-Object -TypeName PSObject -Property @{
		majorVersion = '1';
		minorVersion = '0'
	}
	if ($Content) {
		$nugetOptions = ($nugetOptions | Add-Member @{contentFolders = $Content} -PassThru)
	}
	$nugetSettings = @{
		id = 'TestPackage';
		version = '1.0.123';
		authors = 'joglethorpe';
		owners = 'Dummy Company';
		projectUrl = 'https://dummy.visualstudio.com/Sandbox';
		description = 'This package is for testing NuGet creation functionality';
		releaseNotes = 'Some stuff to say about the release';
		copyright = 'Copyright 2018'
	}
	$nugetDependencies = @{
		'EcsShared.SharedBase' = '[1.0)';
		'EcsShared.SupportRoles' = '[1.0)'
	}
	$expectedSettings = New-Object -TypeName PSObject -Property @{
		nugetOptions = if ($NoOptions) { $null } else { $nugetOptions };
		nugetSettings = if ($NoSettings) { @{} } else { $nugetSettings };
		nugetDependencies = if ($NoDependencies) { @{} } else { $nugetDependencies }
	}
	return $expectedSettings	
}