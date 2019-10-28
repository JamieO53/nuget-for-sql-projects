function New-DbSolutionProjects {
	<#.Synopsis
	Create DB projects for a new SQL database solution from the DB solution template
	.DESCRIPTION
	Creates a Visual Studio solution for SQL projects with the standard components

	The result is the location of the new solution
	.EXAMPLE
	[xml]$params = Get-Content .\DbSolution.xml
	New-DbSolutionProjects -Parameters $params
	#>
    [CmdletBinding()]
    param
    (
		# The DB Solution Builder parameters
		[xml]$Parameters,
		# The DB Solution folder
		[string]$SolutionFolder,
		# The DB Solution path
		[string]$SolutionPath,
		# The DB Solution template folder
		[string]$TemplateFolder,
		# The location of the solution's Pkg project
		[string]$PkgProjectPath
	)
	$sln = Get-Content $SolutionPath | Out-String
	$sln = Set-SqlProjectInSolution -Parameters $Parameters -SolutionFolder $SolutionFolder -TemplateFolder $TemplateFolder -SolutionFile $sln -PkgProjectPath $PkgProjectPath
	$sln | Out-File -FilePath $SolutionPath -Encoding utf8
}