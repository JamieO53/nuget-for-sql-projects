function Get-SolutionPackages {
	<#.Synopsis
	Get the solution's dependency packages
	.DESCRIPTION
    Gets the content of all the solution's NuGet dependencies and updates the SQL projects' NuGet versions for each dependency
	The project nuget configurations are updated with the new versions.
	.EXAMPLE
	Get-SolutionPackages -SolutionPath C:\VSTS\Batch\Batch.sln -ContentFolder C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath,
		# The folder where the package content is to be installed
		[string]$ContentFolder
	)
	$slnFolder = Split-Path $SolutionPath
	$sln = Split-Path $SolutionPath -Leaf
	$localSources = [string]::Join("' -Source '",(Get-NuGetCachePaths))

	Log "Get solution dependencies"
	$reference = Get-SolutionDependencies $SolutionPath
	$reference.Keys | sort | % {
		$package = $_
		$version = $reference[$package]
		if (-not $global:testing -or (Test-NuGetVersionExists -Id $package -Version $version)) {
			Log "Getting $package $version"
			Get-NuGetPackage -Id $package -Version $version -Sources $localSources -OutputDirectory $ContentFolder
			Set-NuGetDependencyVersion -SolutionPath $SolutionPath -Dependency $package -Version $version
		}
	}
}