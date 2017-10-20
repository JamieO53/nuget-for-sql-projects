function Get-NuGetDbToolsConfigPath {
	if ($Global:testing) {
		"TestDrive:\Configuration\NugetDbTools.config"
	} else {
		"$env:APPDATA\JamieO53\NugetDbTools\NugetDbTools.config"
	}
}

