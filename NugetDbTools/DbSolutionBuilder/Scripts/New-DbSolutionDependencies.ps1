function New-DbSolutionDependencies {
	<#.Synopsis
	Create DB projects for a new SQL database solution from the DB solution template
	.DESCRIPTION
	Creates a Visual Studio solution for SQL projects with the standard components

	The result is the location of the new solution
	.EXAMPLE
	[xml]$params = gc .\DbSolution.xml
	New-DbSolutionProjects -Parameters $params
	#>
    [CmdletBinding()]
    param
    (
		# The DB Solution Builder parameters
		[xml]$Parameters,
		# The location of the solution's Pkg project
		[string]$PkgProjectPath
	)
	Set-ProjectDependencyVersion -Path $pkgProjectPath -Dependency NuGetDbPacker
	if ($Parameters.dbSolution.dependencies.dependency) {
		$Parameters.dbSolution.dependencies.dependency | % {
			Set-ProjectDependencyVersion -Path $pkgProjectPath -Dependency $_.Id
		}
	}
}