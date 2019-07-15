function Get-NuGetPackage {
	<#.Synopsis
	Get the package and its dependency content
	.DESCRIPTION
    Gets the content of all the package and its dependencies
	.EXAMPLE
	Get-NuGetPackage -Id Batch.Batching -Version 0.2.11 -Source 'http://srv103octo01:808/NugetServer/nuget' -OutputDirectory C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
        # The package being retrieved
		[string]$Id,
		# The package version
		[string]$Version,
		# The NuGet server
		[string]$Source,
		# The target for the package content
		[string]$OutputDirectory,
		# The optional Framework version
		[string]$Framework = ''
	)

	$cacheFolder = "$env:userprofile\.nuget\packages\$Id\$Version"
	if (Test-Path $cacheFolder) {
		$targetFolder = "$OutputDirectory\$Id"
		if (-not (Test-Path $targetFolder)) {
			mkdir $targetFolder | Out-Null
		}
		copy $cacheFolder\* $targetFolder -Recurse -Force
	}
}