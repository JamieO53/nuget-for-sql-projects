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
	$options = $Settings.nugetOptions | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' } | ForEach-Object { $_.Name }
	$optionItems = ''
	$options | ForEach-Object {
		$field = $_
		$value = (Invoke-Expression "`$Settings.nugetOptions.$field")
		$optionItems += @"

		<add key=`"$field`" value=`"$value`"/>
"@
	}
	$configText = @"
<?xml version=`"1.0`"?>
<configuration>
	<nugetOptions>
$optionItems
	</nugetOptions>
</configuration>
"@
	[xml]$xml = $configText
	$parentNode = $xml.configuration

	if ($Settings.nugetSettings.Keys.Count -gt 0) {
		$settingsNode = Add-Node -parentNode $parentNode -id nugetSettings
		$Settings.nugetSettings.Keys | ForEach-Object {
			$settingKey = $_
			$settingValue = $Settings.nugetSettings[$_]
			Add-DictionaryNode -parentNode $settingsNode -key $settingKey -value $settingValue
		}
	}

	if ($Settings.nugetDependencies.Keys.Count -gt 0) {
		$dependenciesNode = Add-Node -parentNode $parentNode -id nugetDependencies
		$Settings.nugetDependencies.Keys | ForEach-Object {
			$dependencyKey = $_
			$dependencyValue = $Settings.nugetDependencies[$_]
			Add-DictionaryNode -parentNode $dependenciesNode -key $dependencyKey -value $dependencyValue
		}
	}
	Out-FormattedXml -Xml $xml -FilePath $NugetConfigPath
}