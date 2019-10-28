function Get-NuGetLocalPushTimeout {
	$result = ''
	Get-NuGetDbToolsConfig | ForEach-Object {
		$_ | Where-Object { $_.tools.nuget.pushTimeout } | ForEach-Object { $result = $_.tools.nuget.pushTimeout }
	}
	if (-not $result) {
		$result = '900'
	}
	$result
}
