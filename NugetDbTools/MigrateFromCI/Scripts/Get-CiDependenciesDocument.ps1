function Get-CiDependenciesDocument {
	<#.Synopsis
	Get the Dependencies document for the project
	.DESCRIPTION
	Retrieves the Dependencies.xml document from the default location
	.EXAMPLE
	[xml] $deps = Get-CiDependenciesDocument -SolutionName 'RetailReconFees'
	#>
    [CmdletBinding()]
    [OutputType([xml])]
    param
    (
		# The CI project name
		[string]$SolutionName
	)
	$DependenciesPath = "$env:DevBase\$SolutionName\trunk\RunTime.annexures\Dependencies.xml"
	[xml]$deps = gc $DependenciesPath
	return $deps
}