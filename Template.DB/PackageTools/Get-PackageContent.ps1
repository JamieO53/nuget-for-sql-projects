$SolutionFolder = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
[string]$slnPath=ls $SolutionFolder\*.sln | ? { $_ } | % { $_.FullName }

if (-not (Get-Module NugetProjectPacker)) {
	Import-Module "$SolutionFolder\PowerShell\NugetProjectPacker.psd1"
}

Get-SolutionContent -SolutionPath $slnPath
