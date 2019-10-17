function Get-NuGetCachePaths {
	[string[]]$paths = @("$env:userprofile\.nuget\packages", "${env:ProgramFiles(x86)}\Microsoft SDKs\NuGetPackages")
	$paths
}