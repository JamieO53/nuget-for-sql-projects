function Set-SqlProjectInSolution {
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
		# The DB Solution Builder parameters
		[xml]$Parameters,
		# The DB Solution folder
		[string]$SolutionFolder,
		# The DB Solution template folder
		[string]$TemplateFolder,
		# The body of the solution file
		[string]$SolutionFile
	)
	$templateGuid = '96EEF452-0302-4B98-BDBC-D36A24C21EA8'
	$templateSqlProject = @'

Project("{00D1A9C2-B5F0-4AF3-8072-F6C62B433612}") = "Template.DBProject", "Template.DBProject\Template.DBProject.sqlproj", "{96EEF452-0302-4B98-BDBC-D36A24C21EA8}"
EndProject
'@
	$templateSqlConfiguration = @'

		{96EEF452-0302-4B98-BDBC-D36A24C21EA8}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{96EEF452-0302-4B98-BDBC-D36A24C21EA8}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{96EEF452-0302-4B98-BDBC-D36A24C21EA8}.Debug|Any CPU.Deploy.0 = Debug|Any CPU
		{96EEF452-0302-4B98-BDBC-D36A24C21EA8}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{96EEF452-0302-4B98-BDBC-D36A24C21EA8}.Release|Any CPU.Build.0 = Release|Any CPU
		{96EEF452-0302-4B98-BDBC-D36A24C21EA8}.Release|Any CPU.Deploy.0 = Release|Any CPU
'@
	$slnName = $Parameters.dbSolution.parameters.name
	$newSqlProjects = ''
	$newSqlConfiguration = ''
	$slnName = $Parameters.dbSolution.databases.database.dbname | % {
		$dbName = $_
		$dbGuid = [Guid]::NewGuid().ToString().ToUpper()
		$newSqlProjects += $templateSqlProject.Replace('Template.DBProject', "$slnName.$dbName").Replace($templateGuid, $dbGuid)
		$newSqlConfiguration += $templateSqlConfiguration.Replace($templateGuid, $dbGuid)
		New-SqlProject -SolutionFolder $SolutionFolder -ProjectName "$slnName.$dbName" -TemplateFolder $TemplateFolder
	}
	$newSln = $SolutionFile.Replace($templateSqlProject, $newSqlProjects).Replace($templateSqlConfiguration,$newSqlConfiguration)
	return $newSln
}