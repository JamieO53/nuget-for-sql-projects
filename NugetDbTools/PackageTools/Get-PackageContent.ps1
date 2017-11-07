$SolutionFolder = Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\.."
[string]$slnPath=ls $SolutionFolder\*.sln | ? { $_ } | % { $_.FullName }
$PackageContentFolder = "$SolutionFolder\PackageContent"

if (Test-Path $PackageContentFolder) {
    del $PackageContentFolder\* -Recurse -Force
} else {
    mkdir $PackageContentFolder | Out-Null
}

if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$SolutionFolder\PowerShell\NugetDbPacker.psd1"

$localSource = Get-NuGetLocalSource

Get-CSharpProjects -SolutionPath $slnPath | ? { $_.Project.EndsWith('Pkg') } | % {
    $projPath = "$SolutionFolder\$($_.ProjectPath)"
	$projFolder = Split-Path $projPath
	[xml]$proj = gc $projPath
	$proj.Project.ItemGroup.PackageReference | % {
		$package = $_.Include
		$version = $_.Version
		nuget install $package -Version $version -Source $localSource -OutputDirectory $PackageContentFolder -ExcludeVersion
	}
}

ls $PackageContentFolder -Directory | % {
	ls $_.FullName -Directory | % {
		if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
			mkdir "$SolutionFolder\$($_.Name)"
		}
		copy "$($_.FullName)\*" "$SolutionFolder\$($_.Name)"
	}
}

del $PackageContentFolder -Include '*' -Recurse