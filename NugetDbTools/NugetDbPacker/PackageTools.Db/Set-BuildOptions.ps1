if (-not (sqllocaldb info | Where-Object { $_ -eq 'jamieo53' })) {
	sqllocaldb create jamieo53
}

if (-not (Get-Module NuGetSharedPacker)) {
	Import-Module "$PSScriptRoot\..\PowerShell\NugetSharedPacker.psd1" -Global -DisableNameChecking
}

& $PSScriptRoot\SetSolutionVersionVariable.ps1

$slnFolder = Get-ParentSubFolder "$PSScriptRoot" '*.sln'
$slnPath = Get-ChildItem "$slnFolder\*.sln" | Select-Object -First 1 | ForEach-Object { $_.FullName }
$nuspecPath = "$slnFolder\Package.nuspec"

if (Test-Path $nuspecPath) {
	Set-CSharpProjectVersion -SolutionPath $slnPath -Version $env:AssemblyVersion
}
Set-SqlProjectVersion -SolutionPath $slnPath -Version $env:AssemblyVersion
