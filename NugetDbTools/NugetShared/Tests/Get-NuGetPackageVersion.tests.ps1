Describe "Get-NuGetPackageVersion" {
	if (-not (Get-Module TestUtils -All)) {
		Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1" -Global -DisableNameChecking
	}
	Describe "Test-NuGetVersionExists" {
		$config = @"
<?xml version="1.0"?>
<tools>
	<nuget>
		<source>$env:USERPROFILE\.nuget\packages</source>
	</nuget>
</tools>
"@
	Initialize-NuGetSharedConfig $PSScriptRoot $config
	Context "Existing package" {
		It "Version" { Get-NuGetPackageVersion 'NuGetDbPacker.DbTemplate' | should not be '' }
	}
}