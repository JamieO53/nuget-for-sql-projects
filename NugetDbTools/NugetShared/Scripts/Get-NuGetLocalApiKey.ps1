function Get-NuGetLocalApiKey {
	$config = Get-NuGetDbToolsConfig
	$config.configuration.nugetLocalServer.add | ? { $_.key -eq 'ApiKey' } | % { $_.value }
}