function Test-CiDependenciesMigrated {
	<#.Synopsis
	Check if the project's dependencies have already been migrated
	.DESCRIPTION
	Checks the local NuGet server for the project's dependencies
	.EXAMPLE
	[xml] $deps = Get-CiDependenciesDocument -SolutionName 'RetailReconFees'
	if (Test-CiDependenciesMigrated -DependenciesDoc $deps) {...}
	#>
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
		# The CI project dependencies document
		[xml]$DependenciesDoc
	)
}