if ( Get-Module MigrateFromCI) {
	Remove-Module MigrateFromCI
}
Import-Module "$PSScriptRoot\..\bin\Debug\MigrateFromCI\MigrateFromCI.psm1"

Describe "Get-NuGetPackageVersion" {
	Context "Existing package" {
		It "Version" { Get-NuGetPackageVersion 'BackOfficeAudit.Logging' | should not be '' }
	}
}