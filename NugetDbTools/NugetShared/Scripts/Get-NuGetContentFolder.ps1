function Get-NuGetContentFolder {
	$result = ''
	Get-NuGetDbToolsConfig | ForEach-Object {
		$_ | Where-Object { $_.tools.content.contentFolder } | ForEach-Object { $result = $_.tools.content.contentFolder }
	}
	$result
}