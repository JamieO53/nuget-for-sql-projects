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
	}
	[xml]$proj = gc $projectPath
	$group = $proj.Project.ItemGroup | ? { $_.ArtifactReference }
	
	if (Test-Path $SolutionFolder\Databases)
	{
		ls "$SolutionFolder\Databases\*.dacpac" | % {
			$ref = [IO.Path]::ChangeExtension($_.Name, '')
			$node = @"
  <node>
    <ArtifactReference Include="..\Databases\$ref.dacpac">
      <HintPath>..\Databases\$ref.dacpac</HintPath>
      <SuppressMissingDependenciesErrors>False</SuppressMissingDependenciesErrors>
    </ArtifactReference>
  </node>
"@
			$dummy = $group.AppendChild($group.OwnerDocument.ImportNode($node.node.FirstChild, $true))
		}
	}
	Out-FormattedXML -XML $proj -FilePath $projectPath
}