function Get-NuGetPackage {
	<#.Synopsis
	Get the package and its dependency content
	.DESCRIPTION
    Gets the content of all the package and its dependencies
	.EXAMPLE
	Get-NuGetPackage -Id Batch.Batching -Version 0.2.11 -Source 'https://pkgs.dev.azure.com/epsdev/_packaging/EpsNuGet/nuget/v3/index.json' -OutputDirectory C:\VSTS\Batch\PackageContent
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

	if ($Framework) {
		$frameworkVersion = " -Framework $Framework"
	} else {
		$frameworkVersion = ''
	}
	Invoke-Trap "nuget install $Id -Version '$Version' -Source '$Sources' -OutputDirectory '$OutputDirectory' -ExcludeVersion$frameworkVersion" -Message "Failed retrieving $Id $Version" -Fatal
}