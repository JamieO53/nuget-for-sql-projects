if (-not (Get-Module NugetSharedPacker -All)) {
	Import-Module "$PSScriptRoot\NugetSharedPacker.psd1" -Global
}
