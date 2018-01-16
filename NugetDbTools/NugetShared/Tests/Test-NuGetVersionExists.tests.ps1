if ( Get-Module NugetShared) {
	Remove-Module NugetShared
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetShared\NugetShared.psm1"

Describe "Test-NuGetVersionExists" {
	Context "Package Existance" {
		It "Exists" { Test-NuGetVersionExists -Id NuGetShared -Version 0.1.58 | should be $true }
		It "Does not exist" { Test-NuGetVersionExists -Id NuGetDbPacker -Version 0.1.0 | should be $false }
	}
}