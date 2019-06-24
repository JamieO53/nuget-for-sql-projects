function Initialize-NuGetRuntime {
	<#.Synopsis
	Initialize the NuGet Runtime folder
	.DESCRIPTION
	Tests if a Runtime folder exists in the project folder or the solution folder.
	If they do then the contents are copied to the Nuget contents\Runtime folder.
	.EXAMPLE
	Initialize-DbPackage -ProjectPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.sqlproj
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sqlproj file of the project being packaged
        [string]$ProjectPath,
		# The solution file
		[string]$SolutionPath,
		# The location of the NuGet folders
		[string]$Path
	)
	$paths = @()
	$solutionFolder = Split-Path $SolutionPath
	$projectFolder = Split-Path $ProjectPath
	$contentFolder = "$Path\content\Runtime"
	if ((Test-Path $solutionFolder\Runtime) -or (Test-Path $projectFolder\Runtime)) {
		if (-not (Test-Path $contentFolder)) {
			mkdir $contentFolder
		}
		if (Test-Path $solutionFolder\Runtime) {
			copy $solutionFolder\Runtime\* $contentFolder -Recurse
		}
		if (Test-Path $projectFolder\Runtime) {
			copy $projectFolder\Runtime\* $contentFolder -Recurse
		}
	}
}