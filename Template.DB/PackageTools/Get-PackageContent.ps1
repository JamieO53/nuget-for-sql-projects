if ( Get-Module NugetSharedPacker -All) {
	Remove-Module NugetSharedPacker
}
Import-Module "$PSScriptRoot\..\PowerShell\NugetSharedPacker.psd1" -Global -DisableNameChecking

$SolutionFolder = Get-ParentSubFolder "$PSScriptRoot" '*.sln'
[string]$slnPath=ls $SolutionFolder\*.sln | ? { $_ } | % { $_.FullName }

if (-not (Get-Module NugetSharedPacker)) {
	Import-Module "$SolutionFolder\PowerShell\NugetSharedPacker.psd1"
}
Log "Configuration path: $(Get-NuGetDbToolsConfigPath)"
try {
	Log 'Get solution content'
	Get-SolutionContent -SolutionPath $slnPath
} catch {
	Log -Error 'Get-PackageContent failed'
	Log -Error $_
}
