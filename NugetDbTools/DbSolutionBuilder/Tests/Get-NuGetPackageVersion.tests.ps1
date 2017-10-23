if ( Get-Module DbSolutionBuilder) {
	Remove-Module DbSolutionBuilder
}
Import-Module "$PSScriptRoot\..\bin\Debug\DbSolutionBuilder\DbSolutionBuilder.psm1"

Describe "Get-NuGetPackageVersion" {
	Context "Existing package" {
		It "Version" { Get-NuGetPackageVersion 'BackOfficeAudit.Logging' | should not be '' }
	}
}