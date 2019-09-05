if (Get-Module NugetShared) {
	Remove-Module NugetShared
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetShared\NugetShared.psm1" -Global -DisableNameChecking

$Global:testing = $true
$oldConfig = @"
<?xml version="1.0"?>
<configuration>
	<nugetLocalServer>
		<add key="ApiKey" value="Test Key"/>
		<add key="Source" value="Local Server"/>
	</nugetLocalServer>
</configuration>
"@
$config = @"
<?xml version="1.0"?>
<configuration>
	<nugetLocalServer>
		<add key="ApiKey" value="Test Key"/>
		<add key="Source" value="Local Server"/>
		<add key="PushSource" value="Local Server Push"/>
	</nugetLocalServer>
</configuration>
"@
Describe "Get-NuGetLocalPushSource" {
	$path = Get-NuGetDbToolsConfigPath
	$folder = Split-Path $path
	mkdir $folder
	$oldConfig | Set-Content -Path $path
	Context "No Push Source" {
		It "Default to Source" {
			Get-NuGetLocalPushSource | should be 'Local Server'
		}
	}
	$config | Set-Content -Path $path
	Context "Push Source" {
		It "Default to Source" {
			Get-NuGetLocalPushSource | should be 'Local Server Push'
		}
	}
}
$Global:testing = $false
