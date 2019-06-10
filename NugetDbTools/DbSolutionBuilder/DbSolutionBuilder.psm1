if (-not (Get-Module NugetSharedPacker -All)) {
	Import-Module "$PSScriptRoot\NugetSharedPacker.psd1"
}
Import-Module "$PSScriptRoot\NuGetShared.psd1"
Import-Module "$PSScriptRoot\NuGetSharedPacker.psd1"

