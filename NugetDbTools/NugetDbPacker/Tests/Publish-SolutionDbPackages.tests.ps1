if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetDbPacker\NugetDbPacker.psm1" -Global -DisableNameChecking

Describe "Publish-SolutionDbPackages" {
	Context "Exists" {
		It "Runs" {
			$sln = (Get-Item -LiteralPath "$PSScriptRoot\..\..\..\Template.Db\Template.Db.sln").FullName
			Publish-SolutionDbPackages -SolutionPath $sln
		}
	}
}
if (Test-Path "$PSScriptRoot\..\..\..\Template.Db\Template.DBProject\NuGet") {
	Remove-Item -Path "$PSScriptRoot\..\..\..\Template.Db\Template.DBProject\NuGet*" -Recurse -Force
}