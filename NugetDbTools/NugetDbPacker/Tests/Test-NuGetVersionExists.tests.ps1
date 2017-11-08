if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetDbPacker\NugetDbPacker.psm1"

Describe "Test-NuGetVersionExists" {
	Context "Package Existance" {
		It "Exists" { Test-NuGetVersionExists -Id NuGetDbPacker -Version 0.1.14 | should be $true }
		It "Does not exist" { Test-NuGetVersionExists -Id NuGetDbPacker -Version 0.1.0 | should be $false }
	}
}