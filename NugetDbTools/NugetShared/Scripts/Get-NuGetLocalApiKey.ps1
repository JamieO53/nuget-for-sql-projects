function Get-NuGetLocalApiKey {
	$result = ''
	Get-NuGetDbToolsConfig | ForEach-Object {
		$_ | Where-Object { $_.tools.nuget.apiKey } | ForEach-Object { $result = $_.tools.nuget.apiKey }
	}
	$result
}