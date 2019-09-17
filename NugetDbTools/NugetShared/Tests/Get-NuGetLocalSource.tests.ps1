if (-not (Get-Module TestUtils -All)) {
	Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1" -Global -DisableNameChecking
}
$config = @"
<?xml version="1.0"?>
<tools>
	<nuget>
		<source>Local Server</source>
		<apiKey>Test Key</apiKey>
	</nuget>
</tools>
"@
Describe "Get-NuGetLocalSource" {
	Initialize-NuGetSharedConfig $PSScriptRoot $config
	Context "Exists" {
		It "Runs" {
			Get-NuGetLocalSource | should be 'Local Server'
		}
	}
}