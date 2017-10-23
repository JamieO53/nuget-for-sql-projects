if ( Get-Module DbSolutionBuilder) {
	Remove-Module DbSolutionBuilder
}
Import-Module "$PSScriptRoot\..\bin\Debug\DbSolutionBuilder\DbSolutionBuilder.psm1"

Describe "Test-NuGetPackage" {
	Context "Package on local server" {
		It "Exists" { Test-NugetPackage -PackageName 'BackOfficeAudit.Logging' | should be $true }
		It "Does not exists" { Test-NugetPackage -PackageName 'Something.Else' | should be $false }
	}
}