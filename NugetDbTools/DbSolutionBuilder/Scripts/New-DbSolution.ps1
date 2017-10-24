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
	$tempPath = "$env:TEMP\$([Guid]::NewGuid())\template"
	mkdir $tempPath | Out-Null
	nuget install NuGetDbPacker.DbTemplate -source (Get-NuGetLocalSource) -outputDirectory $tempPath -ExcludeVersion
	$solutionLocation = $Parameters.dbSolution.parameters.location
	$solutionName = $Parameters.dbSolution.parameters.name
	$slnPath = "$solutionLocation\$solutionName"
	mkdir $slnPath | Out-Null
	$templatePath = "$tempPath\NuGetDbPacker.DbTemplate\Template\Template.DB"
	copy "$templatePath\Template.DBPkg\*" "$slnPath\$($SolutionName)Pkg" -Recurse
	copy "$templatePath\Template.DB.sln" "$slnPath"
}