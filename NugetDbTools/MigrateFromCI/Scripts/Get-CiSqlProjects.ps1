function Get-CiSqlProjects {
	<#.Synopsis
	Get the names of the project's databases
	.DESCRIPTION
	Extracts a list of the project's databases in the form <ProjectName>.<DatabaseName>
	For an introduced or extended database, or a test database, for example RetailRecon, the data source alias is used.
	For Defines, the implementation name is used.
	.EXAMPLE
	[xml] $deps = Get-CiDependenciesDocument -SolutionName 'RetailReconFees'
	$dbs = GetCiSqlProjects -DependenciesDoc $deps
	#>
    [CmdletBinding()]
    [OutputType([string[]])]
    param
    (
		# The CI project dependencies document
		[xml]$DependenciesDoc
	)
	$projects = [string[]]@()
	$name = $DependenciesDoc.Component.name
	$DependenciesDoc.Component.DataSources.Defines.Define | % {
		$projects += "$name.$($_.Implementation)"
	}
	$DependenciesDoc.Component.DataSources.SelectNodes('Introduced|Extended|TestIntroduce|TestExtension') | % {
		$projects += "$name.$($_.alias)"
	}
	return $projects
}