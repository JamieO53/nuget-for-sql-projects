function Export-NuGetSettings {
	<#.Synopsis
	Initializes the project's NuGet configuration file
	.DESCRIPTION
	Exports the settings to the project's NuGet configuration file
	.EXAMPLE
	Export-NuGetSettings -NugetConfigPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.nuget.config -Settings $settings
	#>
    [CmdletBinding()]
    param
    (
        # The location of .nuget.config file of the project being packaged
        [string]$NugetConfigPath,
		# The values to be set in the NuGet spec
		[PSObject]$Settings
	)
	$major = $Settings.nugetOptions.majorVersion
	$minor = $Settings.nugetOptions.minorVersion
	$configText = @"
<?xml version=`"1.0`"?>
<configuration>
	<nugetOptions>
		<add key=`"majorVersion`" value=`"$major`"/>
		<add key=`"minorVersion`" value=`"$minor`"/>
	</nugetOptions>
</configuration>
"@
	[xml]$xml = $configText
	$parentNode = $xml.configuration

	if ($Settings.nugetSettings.Keys.Count -gt 0) {
		$Settings.nugetSettings.Keys | select -First 1 | % {
			$settingKey = $_
			$settingValue = $Settings.nugetSettings[$_]
		}
		$settingText = @"
<?xml version=`"1.0`"?>
<configuration>
	<nugetSettings>
		<add key=`"$settingKey`" value=`"$settingValue`"/>
	</nugetSettings>
</configuration>
"@
		[xml]$SettingsXml = $settingText
		$settingsNode = $SettingsXml.configuration.nugetSettings
		$Settings.nugetSettings.Keys | select -Skip 1 | % {
			$settingKey = $_
			$settingValue = $Settings.nugetSettings[$_]
			Add-DictionaryNode -parentNode $settingsNode -key $settingKey -value $settingValue
		}
		$childNode = $parentNode.AppendChild($parentNode.OwnerDocument.ImportNode($settingsNode, $true))
	}

	if ($Settings.nugetDependencies.Keys.Count -gt 0) {
		$Settings.nugetDependencies.Keys | select -First 1 | % {
			$dependencyKey = $_
			$dependencyValue = $Settings.nugetDependencies[$_]
		}
		$dependencyText = @"
<?xml version=`"1.0`"?>
<configuration>
	<nugetDependencies>
		<add key=`"$dependencyKey`" value=`"$dependencyValue`"/>
	</nugetDependencies>
</configuration>
"@
		[xml]$dependencyXml = $dependencyText
		$dependenciesNode = $dependencyXml.configuration.nugetDependencies
		$Settings.nugetDependencies.Keys | select -Skip 1 | % {
			$dependencyKey = $_
			$dependencyValue = $Settings.nugetDependencies[$_]
			Add-DictionaryNode -parentNode $dependenciesNode -key $dependencyKey -value $dependencyValue
		}
		$childNode = $parentNode.AppendChild($parentNode.OwnerDocument.ImportNode($dependenciesNode, $true))
	}
	Out-FormattedXml -Xml $xml -FilePath $NugetConfigPath
}