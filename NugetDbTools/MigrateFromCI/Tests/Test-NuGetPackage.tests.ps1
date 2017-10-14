if ( Get-Module MigrateFromCI) {
	Remove-Module MigrateFromCI
}
Import-Module "$PSScriptRoot\..\bin\Debug\MigrateFromCI\MigrateFromCI.psm1"

Describe "Test-NuGetPackage" {
	Context "Package on local server" {
		It "Exists" { Test-NugetPackage -PackageName 'BackOfficeAudit.Logging' | should be $true }
		It "Does not exists" { Test-NugetPackage -PackageName 'Something.Else' | should be $false }
	}
}