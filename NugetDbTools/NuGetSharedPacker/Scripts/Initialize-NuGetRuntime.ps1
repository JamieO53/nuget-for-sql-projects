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
	$contentFolder = Get-NuGetContentFolder
	$contentFolder = "$Path\content\$contentFolder"
	if ((Test-Path $solutionFolder\$contentFolder) -or (Test-Path $projectFolder\$contentFolder)) {
		if (-not (Test-Path $contentFolder)) {
			mkdir $contentFolder
		}
		if (Test-Path $solutionFolder\$contentFolder) {
			copy $solutionFolder\$contentFolder\* $contentFolder -Recurse
		}
		if (Test-Path $projectFolder\$contentFolder) {
			copy $projectFolder\$contentFolder\* $contentFolder -Recurse
		}
	}
}