if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$PSScriptRoot\..\PowerShell\NugetDbPacker.psd1"

$slnFolder = Get-ParentSubFolder "$PSScriptRoot" '*.sln'
$slnPath = ls "$slnFolder\*.sln" | select -First 1 | % { $_.FullName }
$branch = Get-Branch $slnFolder

Get-SqlProjects -SolutionPath $slnPath | % {
	$projName = $_.Project
	$projPath = "$slnFolder\$($_.ProjectPath)"
	$dacpacName = "$projName.dacpac"
	$dacpacPath = "$slnFolder\Databases\$dacpacName"
	$projectDacpacPath = "$slnFolder\$projName\Databases\$dacpacName"
	copy $projectDacpacPath* $slnFolder\Databases
	$profilePath = Find-PublishProfilePath -ProjectPath $projPath
	if (Test-Path $profilePath) {
		if (Test-Path $dacpacPath) {
			Log "Deploying $projName database"
			Publish-ProjectDatabase -DacpacPath $dacpacPath -ProfilePath $profilePath
		} else {
			Log "Database $projName not deployed: $dacpacPath not found"
		}
	} else {
		Log "Database $projName not deployed: no publish profile found"
	}
}
