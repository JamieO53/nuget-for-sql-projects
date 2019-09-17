function Get-NuGetContentFolder {
	$result = ''
	Get-NuGetDbToolsConfig | % {
		$_ | ? { $_.tools.content.contentFolder } | % { $result = $_.tools.content.contentFolder }
	}
	$result
}