function Test-NuGetVersionExists {
	<#.Synopsis
	Test if the package version is on the server
	.DESCRIPTION
	The local NuGet repository is queried for the specific version of the specifiec package
	.EXAMPLE
	if (Test-NuGetVersionExists -Id 'EcsShared.EcsCore' -Version '1.0.28')
	#>
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
		# The package being tested
		[string]$Id,
		[string]$Version
	)
	$exists = $false
	nuget List $Id -AllVersions -Source (Get-NuGetLocalSource) -PreRelease -NonInteractive | ? {
		$_.Equals("$Id $Version") 
	} | % {
		$exists = $true 
	}
	return $exists
}