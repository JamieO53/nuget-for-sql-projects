if ( Get-Module NugetDbPacker -All) {
	Remove-Module NugetDbPacker
}
Import-Module "$PSScriptRoot\..\PowerShell\NugetDbPacker.psd1" -Global -DisableNameChecking

$slnFolder = Get-ParentSubFolder "$PSScriptRoot" '*.sln'
$slnPath = Get-ChildItem "$slnFolder\*.sln" | Select-Object -First 1 | ForEach-Object { $_.FullName }
$branch = Get-Branch $slnFolder

Get-SqlProjects -SolutionPath $slnPath | ForEach-Object {
	$projName = $_.Project
	$projPath = "$slnFolder\$($_.ProjectPath)"
	$projFolder = Split-Path $projPath
	$dacpacName = "$projName.dacpac"
	$dacpacPath = "$slnFolder\Databases\$dacpacName"
	$projectDacpacPath = "$projFolder\Databases\$dacpacName"
	Copy-Item $projectDacpacPath* $slnFolder\Databases
	$profilePath = Find-PublishProfilePath -ProjectPath $projPath
	if (Test-Path $profilePath) {
		if (Test-Path $dacpacPath) {
			Log 'Enable CLR'
			Enable-CLR $profilePath
			Log "Deploying $projName database"
			Publish-ProjectDatabase -DacpacPath $dacpacPath -ProfilePath $profilePath
		} else {
			Log "Database $projName not deployed: $dacpacPath not found"
		}
	} else {
		Log "Database $projName not deployed: no publish profile found"
	}
}
