if ( Get-Module NugetSharedPacker) {
	Remove-Module NugetSharedPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetSharedPacker\NugetSharedPacker.psm1"

Describe "Get-ProjectDependencyVersion" {
	Context "No Pkg project" {
		It "Runs" {

		}
	}
}