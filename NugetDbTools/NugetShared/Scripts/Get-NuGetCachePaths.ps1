function Get-NuGetCachePaths {
	[string[]]$paths = @("$env:userprofile\.nuget\packages", 'Microsoft Visual Studio Offline Packages')
	$paths
}