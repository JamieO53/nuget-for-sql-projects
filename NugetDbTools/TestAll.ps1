$SolutionFolder = Split-Path -Path $MyInvocation.MyCommand.Path
$SolutionPath = ls "$SolutionFolder\*.sln"
if (-not (Get-Module NuGetShared)) {
	Import-Module "$SolutionFolder\NugetShared\bin\Debug\NuGetShared\NuGetShared.psd1"
}
if (-not (Test-Path "$SolutionFolder\TestResults")) {
	md "$SolutionFolder\TestResults"
}
Get-PowerShellProjects -SolutionPath $SolutionPath | % {
	if (Get-Module NuGetShared) {
		Remove-Module NuGetShared
	}
	$projectFolder = Split-Path "$SolutionFolder\$($_.ProjectPath)"
	Invoke-Pester "$projectFolder\Tests" -OutputFile "$SolutionFolder\TestResults\$($_.Project).xml" -OutputFormat NUnitXml
	if (Get-Module $_.Project) {
		Remove-Module $_.Project
	}
}