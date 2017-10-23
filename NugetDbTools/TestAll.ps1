$SolutionFolder = Split-Path -Path $MyInvocation.MyCommand.Path
$SolutionPath = ls "$SolutionFolder\*.sln"
if (-not (Get-Module NuGetShared)) {
	Import-Module "$SolutionFolder\NugetShared\bin\Debug\NuGetShared\NuGetShared.psd1"
}
if (-not (Test-Path "$SolutionFolder\TestResults")) {
	md "$SolutionFolder\TestResults"
}
Get-PowerShellProjects -SolutionPath $SolutionPath | % {
	$projectFolder = Split-Path "$SolutionFolder\$($_.ProjectPath)"
	if (Test-Path "$projectFolder\Tests")
	{
		if (Get-Module NuGetShared) {
			Remove-Module NuGetShared
		}
		Invoke-Pester "$projectFolder\Tests" -OutputFile "$SolutionFolder\TestResults\$($_.Project).xml" -OutputFormat NUnitXml
		if (Test-Path variable:\global:testing) {
			$Global:testing = $false
		}
		if (Get-Module $_.Project) {
			Remove-Module $_.Project
		}
	}
}