function New-SqlProject {
	<#.Synopsis
	Create a new SQL database project
	.DESCRIPTION
	Creates a Visual Studio SQL project with the standard components

	The result is the location of the new solution
	.EXAMPLE
	New-SqlProject -SolutionFolder $SolutionFolder -ProjectName "$slnName.$dbName" -TemplateFolder $TemplateFolder
	#>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
		# The DB Solution Builder parameters
		[xml]$Parameters,
		# The DB Solution folder
		[string]$SolutionFolder,
		# The DB Project name
		[string]$ProjectName,
		# The DB name
		[string]$DbName,
		# The DB Solution template folder
		[string]$TemplateFolder,
		# The location of the solution's Pkg project
		[string]$PkgProjectPath
	)
	$projectFolder = "$SolutionFolder\$ProjectName"
	$projectPath = "$projectFolder\$projectName.sqlproj"
	$slnName = $Parameters.dbSolution.parameters.name
	$slnPath = "$SolutionFolder\$slnName.sln"
	mkdir $projectFolder | Out-Null
	ls "$TemplateFolder\NuGetDbPacker.DbTemplate\Template\Template.DBProject\*" | % {
		$templateFile = $_
		$projectFile = $templateFile.Name.Replace('Template.DBProject', "$ProjectName")
		copy $templateFile.FullName "$projectFolder\$projectFile"
		$text = gc "$projectFolder\$projectFile" | Out-String
		$text = $text.Replace('Template.DBProject', $ProjectName)
		$text = $text.Replace('DBProject', $DbName)
		$text | Set-Content "$projectFolder\$projectFile" -Encoding UTF8
	}
	$cfgPath = [IO.Path]::ChangeExtension($projectPath, '.nuget.config')
	[xml]$proj = gc $PkgProjectPath
	$proj.Project.ItemGroup.PackageReference | % {
		$package = $_.Include
		$version = $_.Version
		Set-NuGetProjectDependencyVersion -NugetConfigPath $cfgPath -SolutionPath $slnPath -Dependency $_.Include -Version $_.Version
	}
	Set-DbReferencesInProject -SolutionFolder $SolutionFolder -ProjectPath $projectPath
	Set-NuGetDependenciesInPkgProject -Parameters $Parameters -ProjectPath $projectPath -SolutionPath $slnPath
}