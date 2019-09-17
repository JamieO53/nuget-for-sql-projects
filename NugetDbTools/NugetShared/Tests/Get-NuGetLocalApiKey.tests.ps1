if (-not (Get-Module TestUtils -All)) {
	Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1" -Global -DisableNameChecking
}
Describe "Get-NuGetLocalApiKey" {
	$config = @"
<?xml version="1.0"?>
<tools>
	<nuget>
		<source>Local Server</source>
		<pushTimeout>900</pushTimeout>
		<apiKey>Test Key</apiKey>
	</nuget>
</tools>
"@
	Initialize-NuGetSharedConfig $PSScriptRoot $config
	Context "Exists" {
		It "Runs" {
			Get-NuGetLocalApiKey | should be 'Test Key'
		}
	}
}