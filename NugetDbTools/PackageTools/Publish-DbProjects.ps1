if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$PSScriptRoot\..\NugetDbPacker\bin\Debug\NuGetDbPacker\NuGetDbPacker.psd1"

$slnFolder = Get-ParentSubFolder "$PSScriptRoot" '*.sln'
$slnPath = ls "$slnFolder\*.sln" | select -First 1 | % { $_.FullName }
Publish-SolutionDbPackages $slnPath