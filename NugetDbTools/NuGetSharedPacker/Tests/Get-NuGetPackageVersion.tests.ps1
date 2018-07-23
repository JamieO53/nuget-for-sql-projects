if ( Get-Module NugetSharedPacker) {
	Remove-Module NugetSharedPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetSharedPacker\NugetSharedPacker.psm1"

Describe "Get-NuGetPackageVersion" {
	Context "Existing package" {
		It "Version" { Get-NuGetPackageVersion 'NuGetDbPacker.DbTemplate' | should not be '' }
	}
}