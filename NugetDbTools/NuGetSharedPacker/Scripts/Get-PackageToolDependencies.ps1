function Get-PackageToolDependencies {
	<#.Synopsis
	Get the solution's  package tool dependencies
	.DESCRIPTION
    Gets the name and version of all the solution's package tool NuGet dependencies
	.EXAMPLE
	Get-PackageToolDependencies -SolutionPath C:\VSTS\Batch\Batch.sln
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
    $reference = @{}
    $all = Get-AllSolutionDependencies -SolutionPath $SolutionPath
    $all.Keys | Where-Object { $_ -like 'Nuget*'} |
        ForEach-Object {
            $reference[$_] = $all[$_]
        }
    $reference
}
