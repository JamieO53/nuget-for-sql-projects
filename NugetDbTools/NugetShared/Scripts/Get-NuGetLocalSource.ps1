function Get-NuGetLocalSource {
	$result = ''
	Get-NuGetDbToolsConfig | % {
		$_ | ? { $_.tools.nuget.source } | % { $result = $_.tools.nuget.source }
	}
	iex "`"$result`"" # Expand embedded variables
}