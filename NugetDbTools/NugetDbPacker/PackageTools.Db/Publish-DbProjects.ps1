if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$PSScriptRoot\..\PowerShell\NugetDbPacker.psd1"
Import-Module "$PSScriptRoot\..\PowerShell\NugetShared.psd1"

$slnFolder = Get-ParentSubFolder "$PSScriptRoot" '*.sln'
$slnPath = ls "$slnFolder\*.sln" | select -First 1 | % { $_.FullName }
Publish-SolutionDbPackages $slnPath
exit $LASTEXITCODE