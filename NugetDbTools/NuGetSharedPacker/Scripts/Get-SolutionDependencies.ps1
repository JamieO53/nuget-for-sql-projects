function Get-SolutionDependencies {
	<#.Synopsis
	Get the solution's dependencies
	.DESCRIPTION
    Gets the name and version of all the solution's NuGet dependencies
	.EXAMPLE
	Get-SolutionDependencies -SolutionPath C:\VSTS\Batch\Batch.sln
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
	$reference = @{}
    $all = Get-AllSolutionDependencies -SolutionPath $SolutionPath
    $all.Keys | Where-Object { $_ -notlike 'Nuget*'} |
        ForEach-Object {
            $reference[$_] = $all[$_]
        }
	$reference
}