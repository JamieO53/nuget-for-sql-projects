function Get-NuGetLocalApiKey {
	$result = ''
	Get-NuGetDbToolsConfig | % {
		$_ | ? { $_.tools.nuget.apiKey } | % { $result = $_.tools.nuget.apiKey }
	}
	$result
}