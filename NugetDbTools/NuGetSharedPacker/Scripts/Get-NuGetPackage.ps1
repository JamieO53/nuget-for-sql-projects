function Get-NuGetPackage {
	<#.Synopsis
	Get the package and its dependency content
	.DESCRIPTION
    Gets the content of all the package and its dependencies
	.EXAMPLE
	Get-NuGetPackage -Id Batch.Batching -Version 0.2.11 -Source 'https://nuget.pkg.github.com/JamieO53/index.json' -OutputDirectory C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
        # The package being retrieved
		[string]$Id,
		# The package version
		[string]$Version,
		# The NuGet servers
		[string]$Sources,
		# The target for the package content
		[string]$OutputDirectory,
		# The optional Framework version
		[string]$Framework = ''
	)

	$cacheFolder = "$env:userprofile\.nuget\packages\$id\$version"
	mkdir $OutputDirectory\$id | Out-Null
	Copy-Item $cacheFolder\* $OutputDirectory\$id -Recurse -Force
}