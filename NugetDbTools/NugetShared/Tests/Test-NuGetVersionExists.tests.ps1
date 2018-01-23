if ( Get-Module NugetShared) {
	Remove-Module NugetShared
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetShared\NugetShared.psm1"

Describe "Test-NuGetVersionExists" {
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