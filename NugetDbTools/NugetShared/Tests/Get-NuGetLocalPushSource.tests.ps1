if (-not (Get-Module TestUtils -All)) {
	Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1" -Global -DisableNameChecking
}

$oldConfig = @"
<?xml version="1.0"?>
<tools>
	<nuget>
		<source>Local Server</source>
		<pushTimeout>900</pushTimeout>
		<apiKey>Test Key</apiKey>
	</nuget>
</tools>
"@
$config = @"
<?xml version="1.0"?>
<tools>
	<nuget>
		<source>Local Server</source>
		<pushTimeout>900</pushTimeout>
		<apiKey>Test Key</apiKey>
		<pushSource>Local Server Push</pushSource>
	</nuget>
</tools>
"@
Describe "Get-NuGetLocalPushSource" {
	Context "No Push Source" {
		Initialize-NuGetSharedConfig $PSScriptRoot $oldConfig
		It "Default to Source" {
			Get-NuGetLocalPushSource | should be 'Local Server'
		}
	}
	Context "Push Source" {
		Initialize-NuGetSharedConfig $PSScriptRoot $config
		It "Use PushSource" {
			Get-NuGetLocalPushSource | should be 'Local Server Push'
		}
	}
}