if (Get-Module NugetShared) {
	Remove-Module NugetShared
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetShared\NugetShared.psm1" -Global -DisableNameChecking

$Global:testing = $true
$config = @"
<?xml version="1.0"?>
<configuration>
	<nugetLocalServer>
		<add key="ApiKey" value="Test Key"/>
		<add key="Source" value="Local Server"/>
	</nugetLocalServer>
</configuration>
"@
Describe "Get-NuGetLocalSource" {
	$path = Get-NuGetDbToolsConfigPath
	$folder = Split-Path $path
	mkdir $folder
	$config | Set-Content -Path $path
	Context "Exists" {
		It "Runs" {
			Get-NuGetLocalSource | should be 'Local Server'
		}
	}
}
$Global:testing = $false
