if (-not (Get-Module TestUtils -All)) {
	Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1" -Global -DisableNameChecking
}

$config = @"
<?xml version="1.0"?>
<tools>
	<nuget>
		<source>Local Server</source>
		<pushTimeout>123</pushTimeout>
		<apiKey>Test Key</apiKey>
	</nuget>
</tools>
"@
Describe "Get-NuGetLocalPushTimeout" {
	Initialize-NuGetSharedConfig $PSScriptRoot $config
	Context "Exists" {
		It "Runs" {
			Get-NuGetLocalPushTimeout | should be '123'
		}
	}
}