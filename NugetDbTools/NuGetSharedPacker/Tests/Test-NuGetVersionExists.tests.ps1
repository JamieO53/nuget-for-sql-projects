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
	Context "Package Existance" {
		$version = Get-NuGetPackageVersion -PackageName NuGetShared
		It "Exists" {
			Test-NuGetVersionExists -Id NuGetShared -Version $version | should be $true 
		}
		It "Does not exist" {
			Test-NuGetVersionExists -Id NuGetDbPacker -Version 0.1.0 | should be $false
		}
	}
}