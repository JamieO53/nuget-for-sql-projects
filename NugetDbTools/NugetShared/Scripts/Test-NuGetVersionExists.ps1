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
		# The version being tested
		[string]$Version
	)
	$exists = $false
	$cmd = "nuget List $Id -AllVersions -Source '$(Get-NuGetLocalSource)'"
	$filter = "$Id $Version"
	$branch = $Version.Split('-', 2).Count -eq 2
	if ($Branch) {
		$cmd += ' -Prerelease'
	}
	Invoke-Expression $cmd | Where-Object {
		$_.Equals($filter) 
	} | ForEach-Object {
		$exists = $true 
	}
	return $exists
}