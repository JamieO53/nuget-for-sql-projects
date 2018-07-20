function Import-NuGetSettings
{
	<#.Synopsis
	Import NuGet settings
	.DESCRIPTION
	Import the NuGet spec settings from the project's NuGet configuration file (<projctName>.nuget.config)
	.EXAMPLE
	Import-NuGetSettings -NugetConfigPath 'EcsShared.SharedBase.nuget.config'
	#>
    [CmdletBinding()]
    [OutputType([Collections.Hashtable])]
    param
    (
        # The project's NuGet configuration file
		[Parameter(Mandatory=$true, Position=0)]
		[string]$NugetConfigPath
	)
	$nugetSettings = New-NuGetSettings

	if (Test-Path $NugetConfigPath) {
        [xml]$cfg = gc $NugetConfigPath
	    $cfg.configuration.nugetOptions.add | % {
		    if ($_.key -eq 'majorVersion') {
			    $nugetSettings.nugetOptions.majorVersion = $_.value
		    } elseif ($_.key -eq 'minorVersion') {
			    $nugetSettings.nugetOptions.minorVersion = $_.value
		    } elseif ($_.key -eq 'contentFolders') {
			    $nugetSettings.nugetOptions.contentFolders = $_.value
		    }
	    }
	    $cfg.configuration.nugetSettings.add | ? { $_ } | % {
		    $nugetSettings.nugetSettings[$_.key] = $_.value
	    }
	    $projPath = Split-Path -LiteralPath $NugetConfigPath
	    $nugetSettings.nugetSettings['version'] = Get-ProjectVersion -Path $projPath -MajorVersion $nugetSettings.nugetOptions.majorVersion -minorVersion $nugetSettings.nugetOptions.minorVersion
	    $cfg.configuration.nugetDependencies.add | ? { $_ } | % {
		    $nugetSettings.nugetDependencies[$_.key] = $_.value
	    }
    }
	$nugetSettings
}