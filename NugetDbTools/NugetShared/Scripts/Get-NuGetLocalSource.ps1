function Get-NuGetLocalSource {
	$result = ''
	Get-NuGetDbToolsConfig | ForEach-Object {
		$_ | Where-Object { $_.tools.nuget.source } | ForEach-Object { $result = $_.tools.nuget.source }
	}
	Invoke-Expression "`"$result`"" # Expand embedded variables
}