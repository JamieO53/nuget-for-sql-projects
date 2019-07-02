if (Get-Module NugetShared) {
	Remove-Module NugetShared
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetShared\NugetShared.psm1"

$Global:testing = $true
#$config = @"
#<?xml version="1.0"?>
#<configuration>
#	<nugetLocalServer>
#		<add key="ApiKey" value="Test Key"/>
#		<add key="ContentFolder" value="Content Folder"/>
#		<add key="Source" value="Local Server"/>
#	</nugetLocalServer>
#</configuration>
#"@
$config = @"
<?xml version="1.0"?>
<configuration>
	<nugetLocalServer>
		<add key="ApiKey" value="Test Key"/>
		<add key="ContentFolder" value="Runtime"/>
		<add key="Source" value="Local Server"/>
	</nugetLocalServer>
</configuration>
"@
Describe "Get-NuGetContentFolder" {
	$path = Get-NuGetDbToolsConfigPath
	$folder = Split-Path $path
	mkdir $folder
	$config | Set-Content -Path $path
	Context "Exists" {
		It "Runs" {
			Get-NuGetContentFolder | should be 'Runtime' #'Content Folder'
		}
	}
}
$Global:testing = $false
