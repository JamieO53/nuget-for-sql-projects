function Get-PackageToolsPackages {
	<#.Synopsis
	Get the package tools packages
	.DESCRIPTION
    Gets the content of all the solution's NuGet package tools dependencies and updates the SQL projects' NuGet versions for each dependency
	The project nuget configurations are updated with the new versions.
	.EXAMPLE
	Get-PackageToolsPackages -SolutionPath C:\VSTS\Batch\Batch.sln -ContentFolder C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath,
		# The folder where the package content is to be installed
		[string]$ContentFolder
	)

	Log "Get package tools dependencies"
    $reference = Get-PackageToolDependencies $SolutionPath
	Get-ReferencedPackages -SolutionPath $SolutionPath -Reference $reference -ContentFolder $ContentFolder
}
