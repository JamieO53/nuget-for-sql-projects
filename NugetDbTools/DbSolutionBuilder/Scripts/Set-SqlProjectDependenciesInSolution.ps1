function Set-SqlProjectDependenciesInSolution {
	<#.Synopsis
	Set the new SQL projects in the solution file
	.DESCRIPTION
	Replaces the template SQL project with the new SQL projects in the solution file

	The result is the updated solution file
	.EXAMPLE
	[xml]$params = gc .\DbSolution.xml
	$sln = Set-SqlProjectInSolution -Parameters $params -SolutionFile $sln
	#>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
		# The body of the solution file
		[string]$SolutionPath
	)
	$slnDir = Split-Path $SolutionPath
	Get-SqlProjects -SolutionPath $SolutionPath | % {
		$projectName = $_.Project
		$projectPath = "$slnDir\$($_.ProjectPath)"
		Set-DbReferencesInProject -SolutionFolder $SolutionFolder -ProjectPath $projectPath
	}
}