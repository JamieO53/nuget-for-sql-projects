[CmdletBinding()]
param
(
	# The package being retrieved
	[string]$Id,
	# The package version
	[string]$Version,
	# The target for the package content
	[string]$OutputDirectory
)

$SolutionFolder = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
[string]$slnPath=ls $SolutionFolder\*.sln | ? { $_ } | % { $_.FullName }

if (-not (Get-Module NugetSharedPacker)) {
	Import-Module "$SolutionFolder\PowerShell\NugetSharedPacker.psd1"
}

$localSource = Get-NuGetLocalSource

Get-NuGetPackage -Id $Id -Version $Version -Source $localSource -OutputDirectory $OutputDirectory
