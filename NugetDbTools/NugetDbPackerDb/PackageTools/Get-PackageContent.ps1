if ( Get-Module NugetSharedPacker -All) {
	Remove-Module NugetSharedPacker
}
Import-Module "$PSScriptRoot\..\PowerShell\NugetSharedPacker.psd1"

$SolutionFolder = Get-ParentSubFolder "$PSScriptRoot" '*.sln'
[string]$slnPath=ls $SolutionFolder\*.sln | ? { $_ } | % { $_.FullName }

if (-not (Get-Module NugetSharedPacker)) {
	Import-Module "$SolutionFolder\PowerShell\NugetSharedPacker.psd1"
}

Get-SolutionContent -SolutionPath $slnPath
