function Get-NuGetLocalPushTimeout {
	$result = ''
	Get-NuGetDbToolsConfig | % {
		$_ | ? { $_.tools.nuget.pushTimeout } | % { $result = $_.tools.nuget.pushTimeout }
	}
	if (-not $result) {
		$result = '900'
	}
	$result
}
