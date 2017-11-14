function Set-NuGetDependencyVersion {
	<#.Synopsis
	Update the solution's SQL projects NuGet dependendency version
	.DESCRIPTION
    Checks each SQL project in the solution if it has a NuGet dependency on the given dependency. If it does, the version is updated to the given value.
	.EXAMPLE
	Set-NuGetDependencyVersion -SolutionPath C:\VSTS\Batch\Batch.sln -Dependency 'BackOfficeStateManager.StateManager' -Version '0.1.2'
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath,
		# The dependency being updated
		[string]$Dependency,
		# The new package version
		[string]$Version
	)
    $solutionFolder = Split-Path -Path $SolutionPath
    Get-SqlProjects -SolutionPath $SolutionPath | % {
        $project = $_.Project
        [string]$projectPath = [IO.Path]::Combine($solutionFolder, $_.ProjectPath)
        
    }
}