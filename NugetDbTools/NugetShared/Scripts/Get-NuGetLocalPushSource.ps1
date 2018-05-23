function Get-NuGetLocalPushSource {
	$config = Get-NuGetDbToolsConfig
	$source = $config.configuration.nugetLocalServer.add | ? { $_.key -eq 'PushSource' } | % { $_.value }
	if ([string]::IsNullOrEmpty($source)) {
		$source = $config.configuration.nugetLocalServer.add | ? { $_.key -eq 'Source' } | % { $_.value }
	}
	$source
}