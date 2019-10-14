function Get-ReferencedPackages {
	<#.Synopsis
	Get the referenced packages
	.DESCRIPTION
    Gets the content of all the referenced dependencies and updates the SQL projects' NuGet versions for each dependency
	The project nuget configurations are updated with the new versions.
	.EXAMPLE
	Get-ReferencedPackages -SolutionPath C:\VSTS\Batch\Batch.sln -References $reference -ContentFolder C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
		# The location of .sln file of the solution being updated
		[string]$SolutionPath,
		# The packages being installed
        [hashtable]$reference,
		# The folder where the package content is to be installed
		[string]$ContentFolder
	)

	if (Test-Path $packageContentFolder) {
		Remove-Item $packageContentFolder* -Recurse -Force
	}
	mkdir $packageContentFolder | Out-Null

	$localSources = [string]::Join("' -Source '",(Get-NuGetCachePaths))
	$reference.Keys | Sort-Object | ForEach-Object {
		$package = $_
		$version = $reference[$package]
		if (-not $global:testing -or (Test-NuGetVersionExists -Id $package -Version $version)) {
			Log "Getting $package $version"
			Get-NuGetPackage -Id $package -Version $version -Sources $localSources -OutputDirectory $ContentFolder
			Set-NuGetDependencyVersion -SolutionPath $SolutionPath -Dependency $package -Version $version
		}
	}
}