$SolutionFolder = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
[string]$slnPath=ls $SolutionFolder\*.sln | ? { $_ } | % { $_.FullName }

if (-not (Get-Module NugetSharedPacker)) {
	Import-Module "$SolutionFolder\PowerShell\NugetSharedPacker.psd1"
}

Get-SolutionContent -SolutionPath $slnPath
