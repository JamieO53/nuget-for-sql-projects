$SolutionFolder = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
[string]$slnPath=ls $SolutionFolder\*.sln | ? { $_ } | % { $_.FullName }

if (-not (Get-Module NugetDbPacker)) {
	Import-Module "$SolutionFolder\PowerShell\NugetDbPacker.psd1"
}

$localSource = Get-NuGetLocalSource

Get-NuGetPackage -Id $Id -Version $Version -Source $localSource -OutputDirectory $OutputDirectory
