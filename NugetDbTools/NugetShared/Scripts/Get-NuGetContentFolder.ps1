function Get-NuGetContentFolder {
	$config = Get-NuGetDbToolsConfig
	$config.configuration.nugetLocalServer.add | ? { $_.key -eq 'ContentFolder' } | % { $_.value }
}