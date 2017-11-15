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
		# The DB Solution template folder
		[string]$TemplateFolder
	)
	$projectFolder = "$SolutionFolder\$ProjectName"
	$projectPath = "$projectFolder\$projectName.sqlproj"
	mkdir $projectFolder | Out-Null
	ls "$TemplateFolder\Template.DBProject\Template.DBProject*" | % {
		$templateFile = $_
		$projectFile = $templateFile.Name.Replace('Template.DBProject', "$ProjectName")
		copy $templateFile.FullName "$projectFolder\$projectFile"
		$text = gc "$projectFolder\$projectFile" | Out-String
		$text = $text.Replace('Template.DBProject', $ProjectName)
		$text | sc "$projectFolder\$projectFile" -Encoding UTF8
	}
	Set-DbReferencesInProject -SolutionFolder $SolutionFolder -ProjectPath $projectPath
	Set-NuGetDependenciesInProject -Parameters $Parameters -ProjectPath $projectPath
}