$SolutionFolder = Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\.."
[string]$slnPath=ls $SolutionFolder\*.sln | ? { $_ } | % { $_.FullName }
$packageContentFolder = "$SolutionFolder\PackageContent"

if (-not (Get-Module NugetDbPacker)) {
	Import-Module "$SolutionFolder\PowerShell\NugetDbPacker.psd1"
}

Get-SolutionContent -SolutionPath $slnPath
