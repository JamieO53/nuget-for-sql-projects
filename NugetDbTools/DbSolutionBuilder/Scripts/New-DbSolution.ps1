function New-DbSolution {
	<#.Synopsis
	Create a new SQL database solution
	.DESCRIPTION
	Creates a Visual Studio solution for SQL projects with the standard components

	The result is the location of the new solution
	.EXAMPLE
	[xml]$params = gc .\DbSolution.xml
	New-DbSolution -Parameters $params
	#>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
		# The DB Solution Builder parameters
		[xml]$Parameters
	)
	$solutionName = $Parameters.dbSolution.parameters.name
	$solutionLocation = $Parameters.dbSolution.parameters.location
	$slnFolder = "$solutionLocation\$solutionName"
	$templateFolder = "$env:TEMP\$([Guid]::NewGuid())\template"
    $slnPath = "$slnFolder\$($SolutionName).sln"
	$pkgProjectPath = "$slnFolder\$($SolutionName)Pkg\$($SolutionName)Pkg.csproj"

	New-DbSolutionFromTemplate -Parameters $Parameters -SolutionFolder $slnFolder -TemplateFolder $templateFolder -PkgProjectPath $pkgProjectPath

	New-DbSolutionDependencies -Parameters $Parameters -PkgProjectPath $pkgProjectPath

	Get-SolutionContent -SolutionPath $slnPath

	New-DbSolutionProjects -Parameters $Parameters -SolutionFolder $slnFolder -TemplateFolder $templateFolder -SolutionPath $slnPath -PkgProjectPath $pkgProjectPath

	Return $slnFolder
}