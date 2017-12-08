if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetDbPacker\NugetDbPacker.psm1"

Describe "Publish-SolutionDbPackages" {
	Context "Exists" {
		It "Runs" {
			Publish-SolutionDbPackages -SolutionPath ..\..\..\Template.Db\Template.Db.sln
		}
	}
}