if (Get-Module NugetShared) {
	Remove-Module NugetShared
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetShared\NugetShared.psm1"

Describe "Get-NuGetPackageVersion" {
	Context "Existing package" {
		It "Version" { Get-NuGetPackageVersion 'NuGetDbPacker.DbTemplate' | should not be '' }
	}
}