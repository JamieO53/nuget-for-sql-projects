function Test-NuGetPackage {
	<#.Synopsis
	Tests if the package is available
	.DESCRIPTION
	Checks if the package is available in the local NuGet server
	.EXAMPLE
	if (-not (Test-NuGetPackage -PackageName 'RetailReconFees')) {...}
	#>
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
		# The NuGet package name
		[string]$PackageName
	)
	$result = $false
	nuget list $PackageName -Source (Get-NuGetLocalSource) | % {
		$nameVersion = $_ -split ' '
		if ($nameVersion[0] -eq $PackageName) {
			$result = $true
		}
	}
	return $result
}