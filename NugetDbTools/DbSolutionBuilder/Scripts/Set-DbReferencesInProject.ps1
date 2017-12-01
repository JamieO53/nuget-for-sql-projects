function Set-DbReferencesInProject {
	<#.Synopsis
	Sets the database references in the SQL project file
	.DESCRIPTION
	Adds a database reference for all dacpacs in the solution's Databases folder

	The modified project file is saved to disk
	.EXAMPLE
	Set-DbReferencesInProject -SolutionFolder $SolutionFolder -ProjectPath $projPath
	#>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
		# The DB Solution folder
		[string]$SolutionFolder,
		# The DB Project file path
		[string]$ProjectPath
	)
	[xml]$proj = gc $ProjectPath | Out-String
	$group = $proj.Project.ItemGroup | ? { $_.ArtifactReference }
	
	if (Test-Path $SolutionFolder\Databases)
	{
		ls "$SolutionFolder\Databases\*.dacpac" | % {
			$ref = [IO.Path]::ChangeExtension($_.Name, '')
			$exists = ($group.ArtifactReference | ? { $_.Include -eq "..\Databases\$($ref)dacpac" }) -ne $null
			if (-not $exists) {
				[xml]$node = @"
  <node>
    <ArtifactReference Include="..\Databases\$($ref)dacpac">
      <HintPath>..\Databases\$($ref)dacpac</HintPath>
      <SuppressMissingDependenciesErrors>False</SuppressMissingDependenciesErrors>
    </ArtifactReference>
  </node>
"@
				$dummy = $group.AppendChild($group.OwnerDocument.ImportNode($node.node.FirstChild, $true))
			}
		}
	}
	Out-FormattedXML -XML $proj -FilePath $ProjectPath
}