if (-not (Get-Module NugetShared -All)) {
	Import-Module "$PSScriptRoot\NugetShared.psd1" -Global
}
#if (-not (Get-Module GitExtension -All)) {
#	Import-Module "$PSScriptRoot\GitExtension.psd1"
#}
#if (-not (Get-Module VSTSExtension -All)) {
#	Import-Module "$PSScriptRoot\VSTSExtension.psd1"
#}
Import-Extensions
