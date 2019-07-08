function Get-NuGetLocalPushTimeout {
	$config = Get-NuGetDbToolsConfig
	$source = $config.configuration.nugetLocalServer.add | ? { $_.key -eq 'PushTimeout' } | % { $_.value }
	if ([string]::IsNullOrEmpty($source)) {
		$source = 900
	}
	$source
}
