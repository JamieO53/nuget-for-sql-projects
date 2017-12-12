if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetDbPacker\NugetDbPacker.psm1"

Describe "Publish-SolutionDbPackages" {
	Context "Exists" {
		It "Runs" {
			$sln = (Get-Item -LiteralPath ..\..\..\Template.Db\Template.Db.sln).FullName
			Publish-SolutionDbPackages -SolutionPath $sln
		}
	}
}