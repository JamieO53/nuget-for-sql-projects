function Get-NuGetLocalPushSource {
	$result = ''
	Get-NuGetDbToolsConfig | ForEach-Object {
		$_ | Where-Object { $_.tools.nuget.pushSource } | ForEach-Object { $result = $_.tools.nuget.pushSource }
	}
	if (-not $result) {
		Get-NuGetDbToolsConfig | ForEach-Object {
			$_ | Where-Object { $_.tools.nuget.source } | ForEach-Object { $result = $_.tools.nuget.source }
		}
	}
	$result
}