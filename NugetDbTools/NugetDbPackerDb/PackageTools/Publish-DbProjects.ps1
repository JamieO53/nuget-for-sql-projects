if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$PSScriptRoot\..\PowerShell\NugetDbPacker.psd1" -Global -DisableNameChecking

$slnFolder = Get-ParentSubFolder "$PSScriptRoot" '*.sln'
$slnPath = Get-ChildItem "$slnFolder\*.sln" | Select-Object -First 1 | ForEach-Object { $_.FullName }
try {
	Publish-SolutionDbPackages $slnPath
} catch {
	Write-Error $_
	exit 1
}
exit $LASTEXITCODE