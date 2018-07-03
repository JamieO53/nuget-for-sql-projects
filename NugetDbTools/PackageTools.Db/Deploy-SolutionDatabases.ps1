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
	$profilePath = [IO.Path]::ChangeExtension($projPath, ".$branch.publish.xml")
	if (-not (Test-Path $profilePath)) {
		$profilePath = [IO.Path]::ChangeExtension($projPath, ".publish.xml")
	}
	if (Test-Path $profilePath) {
		if (Test-Path $dacpacPath) {
			Publish-ProjectDatabase -DacpacPath $dacpacPath -ProfilePath $profilePath
		}
	} else {
		Log "Database $projName not deployed: no publish profile found"
	}
}
