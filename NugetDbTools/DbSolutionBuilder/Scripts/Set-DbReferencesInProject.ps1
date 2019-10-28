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
	[xml]$proj = Get-Content $ProjectPath | Out-String
	$group = $proj.Project.ItemGroup | Where-Object { $_.ArtifactReference }
	
	if (Test-Path $SolutionFolder\Databases)
	{
		Get-ChildItem "$SolutionFolder\Databases\*.dacpac" | ForEach-Object {
			$ref = [IO.Path]::ChangeExtension($_.Name, '')
			$exists = ($group.ArtifactReference | Where-Object { $_.Include -eq "..\Databases\$($ref)dacpac" }) -ne $null
			if (-not $exists) {
				$refNode = Add-Node -parentNode $group -id ArtifactReference
				$refNode.SetAttribute('Include', "..\Databases\$($ref)dacpac")
				$hintNode = Add-Node -parentNode $refNode -id HintPath
				Set-NodeText -parentNode $refNode -id HintPath -text "..\Databases\$($ref)dacpac"
				Set-NodeText -parentNode $refNode -id SuppressMissingDependenciesErrors -text False
			}
		}
	}
	Out-FormattedXML -XML $proj -FilePath $ProjectPath
}