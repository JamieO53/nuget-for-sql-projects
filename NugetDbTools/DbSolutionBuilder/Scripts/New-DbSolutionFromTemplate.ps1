function New-DbSolutionFromTemplate {
	<#.Synopsis
	Create a new SQL database solution from the DB solution template
	.DESCRIPTION
	Creates a Visual Studio solution for SQL projects with the standard components

	The result is the location of the new solution
	.EXAMPLE
	[xml]$params = gc .\DbSolution.xml
	New-DbSolutionFromTemplate -Parameters $params
	#>
    [CmdletBinding()]
    param
    (
		# The DB Solution Builder parameters
		[xml]$Parameters,
		# The DB Solution folder
		[string]$SolutionFolder,
		# The DB Solution template folder
		[string]$TemplateFolder,
		# The location of the solution's Pkg project
		[string]$PkgProjectPath
	)
	mkdir $templateFolder | Out-Null
	nuget install NuGetDbPacker.DbTemplate -source (Get-NuGetLocalSource) -outputDirectory $templateFolder -ExcludeVersion

	$solutionName = $Parameters.dbSolution.parameters.name
    $slnPath = "$SolutionFolder\$($SolutionName).sln"

	mkdir "$SolutionFolder\$($SolutionName)Pkg" | Out-Null
	mkdir "$SolutionFolder\PackageTools" | Out-Null

	$templatePath = "$templateFolder\NuGetDbPacker.DbTemplate\Template"
	$toolsPath = "$templateFolder\NuGetDbPacker.DbTemplate\PackageTools"
	copy "$templatePath\Template.DBPkg\Class1.cs" "$SolutionFolder\$($SolutionName)Pkg"
	copy "$templatePath\Template.DBPkg\Template.DBPkg.csproj" $PkgProjectPath
	copy "$templatePath\Template.DB.sln" $slnPath
	copy "$templatePath\.gitignore" $slnPath
	copy "$toolsPath\*" "$SolutionFolder\PackageTools"

	$newGuid = [Guid]::NewGuid().ToString().ToUpperInvariant()
	$sln = gc $slnPath | Out-String
	$sln = $sln.Replace('Template.DBPkg', "$($SolutionName)Pkg").Replace('1D72F9F5-2ED0-4157-9EF8-903203AA428C', $newGuid)
	$sln | Out-File -FilePath $slnPath -Encoding utf8

	iex "$SolutionFolder\PackageTools\Bootstrap.ps1"

	if (-not (Get-Module NugetSharedPacker)) {
		Import-Module "$SolutionFolder\PowerShell\NugetDbPacker.psd1"
	}
}