function Get-NuGetLocalSource {
	$config = Get-NuGetDbToolsConfig
	$config.configuration.nugetLocalServer.add | ? { $_.key -eq 'Source' } | % { $_.value }
}