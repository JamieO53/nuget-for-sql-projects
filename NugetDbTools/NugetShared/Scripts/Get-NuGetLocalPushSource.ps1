function Get-NuGetLocalPushSource {
	$result = ''
	Get-NuGetDbToolsConfig | % {
		$_ | ? { $_.tools.nuget.pushSource } | % { $result = $_.tools.nuget.pushSource }
	}
	if (-not $result) {
		Get-NuGetDbToolsConfig | % {
			$_ | ? { $_.tools.nuget.source } | % { $result = $_.tools.nuget.source }
		}
	}
	$result
}