if (-not (Get-Module NugetShared)) {
	Import-Module "$PSScriptRoot\NugetShared.psd1"
}
if (-not (Get-Module GitExtension)) {
	Import-Module "$PSScriptRoot\GitExtension.psd1"
}
if (-not (Get-Module VSTSExtension)) {
	Import-Module "$PSScriptRoot\VSTSExtension.psd1"
}

