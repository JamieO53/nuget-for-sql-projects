if (-not (Get-Module NugetSharedPacker -All)) {
	Import-Module "$PSScriptRoot\..\PowerShell\NugetSharedPacker.psd1" -Global -DisableNameChecking
}

$slnFolder = Get-ParentSubFolder "$PSScriptRoot" '*.sln'
$nuspecPath = "$slnFolder\Package.nuspec"

if (Test-Path $nuspecPath) {
    [string]$semanticVersion = Measure-ProjectVersion -Path  $nuspecPath -ProjectFolder $slnFolder
} else {
    [string]$semanticVersion = Get-ProjectVersion -Path $slnFolder -MajorVersion 1 -MinorVersion 0 -UpVersion $false
}
$versionBranch = $semanticVersion.Split('-',2)
$assemblyVersion = $versionBranch[0]
if ($versionBranch.Count -eq 2) {
    $assemblyVersion += '.0'
}
Log "Semantic version: $semanticVersion"
Write-Host  "##vso[task.setvariable variable=SemanticVersion;]$semanticVersion"
if (-not $env:SemanticVersion) {
	Set-Item -Path Env:SemanticVersion -Value $semanticVersion
}
Log "Assembly version: $assemblyVersion"
Write-Host  "##vso[task.setvariable variable=AssemblyVersion;]$assemblyVersion"
if (-not $env:AssemblyVersion) {
	Set-Item -Path Env:AssemblyVersion -Value $assemblyVersion
}
